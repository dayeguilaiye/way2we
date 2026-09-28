package account

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/jackc/pgx/v5"
	"way2we/server/internal/platform/identifier"
)

type deliveryError struct {
	cause            error
	jobID, requestID string
	attempt          int
	duration         time.Duration
}

func (e *deliveryError) Error() string { return "email delivery failed" }
func (e *deliveryError) Unwrap() error { return e.cause }

// DeliverOne leases one persisted challenge. Sending is outside the transaction.
// A failed/unknown delivery retries the same challenge and Message-ID.
func (s *Service) DeliverOne(ctx context.Context) (handled bool, returned error) {
	lease := identifier.New()
	var message CodeMail
	var encrypted []byte
	var requestID string
	var attempt int
	started := time.Now()
	defer func() {
		if returned != nil && message.ID != "" {
			returned = &deliveryError{cause: returned, jobID: message.ID, requestID: requestID, attempt: attempt, duration: time.Since(started)}
		}
	}()
	err := s.pool.QueryRow(ctx, `WITH candidate AS (
 SELECT id FROM email_challenges WHERE consumed_at IS NULL AND invalidated_at IS NULL
 AND expires_at>clock_timestamp() AND delivery_state IN ('pending','sending') AND delivery_attempts<5
 AND available_at<=clock_timestamp() AND (lease_until IS NULL OR lease_until<clock_timestamp())
 ORDER BY available_at,id FOR UPDATE SKIP LOCKED LIMIT 1)
 UPDATE email_challenges c SET delivery_state='sending',delivery_attempts=c.delivery_attempts+1,
 lease_token=$1,lease_until=clock_timestamp()+interval '30 seconds'
 FROM candidate WHERE c.id=candidate.id RETURNING c.id,c.email_normalized,c.code_ciphertext,c.request_id,c.delivery_attempts`, lease).Scan(&message.ID, &message.Email, &encrypted, &requestID, &attempt)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("claim code delivery: %w", err)
	}
	message.Code, err = s.open(message.ID, encrypted)
	if err == nil {
		sendCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
		err = s.sender.SendCode(sendCtx, message)
		cancel()
	}
	if err != nil {
		_, saveErr := s.pool.Exec(ctx, `UPDATE email_challenges SET delivery_state=CASE WHEN delivery_attempts>=5 THEN 'failed' ELSE 'pending' END,available_at=clock_timestamp()+interval '10 seconds',lease_until=NULL,lease_token=NULL,code_ciphertext=CASE WHEN delivery_attempts>=5 THEN NULL ELSE code_ciphertext END WHERE id=$1 AND lease_token=$2`, message.ID, lease)
		if saveErr != nil {
			return true, fmt.Errorf("save delivery failure: %w", saveErr)
		}
		return true, fmt.Errorf("send verification email: %w", err)
	}
	_, err = s.pool.Exec(ctx, "UPDATE email_challenges SET delivery_state='sent',code_ciphertext=NULL,lease_until=NULL,lease_token=NULL WHERE id=$1 AND lease_token=$2", message.ID, lease)
	if err != nil {
		return true, fmt.Errorf("finish code delivery: %w", err)
	}
	return true, nil
}
func (s *Service) RunDelivery(ctx context.Context, logger *slog.Logger) {
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()
	cleanup := time.NewTicker(time.Minute)
	defer cleanup.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			for range 10 {
				handled, err := s.DeliverOne(ctx)
				if err != nil {
					if ctx.Err() == nil {
						attrs := []any{"event", "email_delivery_failed", "error_kind", "mail_delivery"}
						var delivery *deliveryError
						if errors.As(err, &delivery) {
							attrs = append(attrs, "job_id", delivery.jobID, "origin_request_id", delivery.requestID, "attempt", delivery.attempt, "duration_ms", delivery.duration.Milliseconds())
						}
						logger.Warn("email delivery will retry or expire", attrs...)
					}
					break
				}
				if !handled {
					break
				}
			}
		case <-cleanup.C:
			err := s.cleanup(ctx)
			if err != nil && ctx.Err() == nil {
				logger.Warn("authentication cleanup failed", "event", "auth_cleanup_failed", "error_kind", "database")
			}
		}
	}
}

// Retain challenge metadata for one day; expired session credentials need no history.
func (s *Service) cleanup(ctx context.Context) error {
	for _, query := range []string{
		"UPDATE email_challenges SET code_hmac=NULL,code_ciphertext=NULL,delivery_state=CASE WHEN delivery_state IN ('pending','sending') THEN 'expired' ELSE delivery_state END WHERE expires_at<=clock_timestamp() AND (code_hmac IS NOT NULL OR code_ciphertext IS NOT NULL)",
		"DELETE FROM email_challenges WHERE expires_at<clock_timestamp()-interval '1 day'",
		"DELETE FROM sessions WHERE expires_at<clock_timestamp() OR revoked_at<clock_timestamp()-interval '1 day'",
		"DELETE FROM auth_limits WHERE expires_at<clock_timestamp()",
	} {
		if _, err := s.pool.Exec(ctx, query); err != nil {
			return fmt.Errorf("cleanup authentication data: %w", err)
		}
	}
	return nil
}
