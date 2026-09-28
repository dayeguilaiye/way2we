package account

import (
	"context"
	"crypto/hmac"
	"errors"
	"fmt"
	"regexp"
	"time"

	"github.com/jackc/pgx/v5"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

// RequestCode persists the encrypted delivery job before acknowledging acceptance.
func (s *Service) RequestCode(ctx context.Context, rawEmail, source, requestID string) (Accepted, error) {
	email, err := NormalizeEmail(rawEmail)
	if err != nil {
		return Accepted{}, err
	}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Accepted{}, fmt.Errorf("begin code request: %w", err)
	}
	defer rollback(tx)
	var now time.Time
	if err = tx.QueryRow(ctx, "SELECT clock_timestamp()").Scan(&now); err != nil {
		return Accepted{}, err
	}
	if err = s.rate(ctx, tx, "send-source", source, now, time.Hour, s.limits.SendPerSource); err != nil {
		return Accepted{}, err
	}
	if err = lock(ctx, tx, s.digest("email", email)); err != nil {
		return Accepted{}, fmt.Errorf("lock email: %w", err)
	}
	if err = tx.QueryRow(ctx, "SELECT clock_timestamp()").Scan(&now); err != nil {
		return Accepted{}, err
	}
	var recent time.Time
	err = tx.QueryRow(ctx, "SELECT created_at FROM email_challenges WHERE email_normalized=$1 ORDER BY created_at DESC LIMIT 1", email).Scan(&recent)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return Accepted{}, err
	}
	if err == nil && now.Sub(recent) < time.Minute {
		return Accepted{}, apperror.New("RATE_LIMITED")
	}
	if err = s.rate(ctx, tx, "send-email", email, now, time.Hour, s.limits.SendPerEmail); err != nil {
		return Accepted{}, err
	}
	if _, err = tx.Exec(ctx, "UPDATE email_challenges SET invalidated_at=$2,code_ciphertext=NULL,code_hmac=NULL WHERE email_normalized=$1 AND consumed_at IS NULL AND invalidated_at IS NULL", email, now); err != nil {
		return Accepted{}, err
	}
	id, code := identifier.New(), newCode()
	_, err = tx.Exec(ctx, `INSERT INTO email_challenges(id,email_normalized,code_hmac,code_ciphertext,created_at,expires_at,available_at,request_id) VALUES($1,$2,$3,$4,$5,$6,$5,$7)`, id, email, s.digest("code", id, email, code), s.seal(id, code), now, now.Add(10*time.Minute), requestID)
	if err != nil {
		return Accepted{}, fmt.Errorf("store challenge: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return Accepted{}, fmt.Errorf("commit challenge: %w", err)
	}
	return Accepted{ResendAfter: 60, ExpiresIn: 600}, nil
}

var codePattern = regexp.MustCompile(`^[0-9]{6}$`)

func (s *Service) Login(ctx context.Context, rawEmail, code, source string) (Session, error) {
	email, err := NormalizeEmail(rawEmail)
	if err != nil {
		return Session{}, err
	}
	if !codePattern.MatchString(code) {
		return Session{}, fieldError("code", "SIX_DIGITS_REQUIRED")
	}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Session{}, fmt.Errorf("begin login: %w", err)
	}
	defer rollback(tx)
	var now time.Time
	if err = tx.QueryRow(ctx, "SELECT clock_timestamp()").Scan(&now); err != nil {
		return Session{}, err
	}
	if err = s.rate(ctx, tx, "verify-source", source, now, 10*time.Minute, s.limits.VerifyPerSource); err != nil {
		return Session{}, err
	}
	if err = lock(ctx, tx, s.digest("email", email)); err != nil {
		return Session{}, err
	}
	if err = tx.QueryRow(ctx, "SELECT clock_timestamp()").Scan(&now); err != nil {
		return Session{}, err
	}
	var id string
	var digest []byte
	var attempts int
	err = tx.QueryRow(ctx, `SELECT id,code_hmac,attempt_count FROM email_challenges WHERE email_normalized=$1 AND consumed_at IS NULL AND invalidated_at IS NULL AND expires_at>$2 ORDER BY created_at DESC LIMIT 1 FOR UPDATE`, email, now).Scan(&id, &digest, &attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		if err = tx.Commit(ctx); err != nil {
			return Session{}, err
		}
		return Session{}, apperror.New("CODE_INVALID_OR_EXPIRED")
	}
	if err != nil {
		return Session{}, fmt.Errorf("load challenge: %w", err)
	}
	if attempts >= 5 || !hmac.Equal(digest, s.digest("code", id, email, code)) {
		_, err = tx.Exec(ctx, `UPDATE email_challenges SET attempt_count=LEAST(attempt_count+1,5),invalidated_at=CASE WHEN attempt_count>=4 THEN $2 ELSE invalidated_at END,code_ciphertext=CASE WHEN attempt_count>=4 THEN NULL ELSE code_ciphertext END,code_hmac=CASE WHEN attempt_count>=4 THEN NULL ELSE code_hmac END WHERE id=$1`, id, now)
		if err != nil {
			return Session{}, err
		}
		if err = tx.Commit(ctx); err != nil {
			return Session{}, err
		}
		return Session{}, apperror.New("CODE_INVALID_OR_EXPIRED")
	}
	var userID string
	err = tx.QueryRow(ctx, "SELECT user_id FROM login_identities WHERE provider='email' AND subject=$1", email).Scan(&userID)
	if errors.Is(err, pgx.ErrNoRows) {
		userID = identifier.New()
		if _, err = tx.Exec(ctx, "INSERT INTO users(id,display_name,created_at,updated_at) VALUES($1,'新朋友',$2,$2)", userID, now); err != nil {
			return Session{}, err
		}
		if _, err = tx.Exec(ctx, "INSERT INTO login_identities(id,user_id,provider,subject,verified_at) VALUES($1,$2,'email',$3,$4)", identifier.New(), userID, email, now); err != nil {
			return Session{}, err
		}
	} else if err != nil {
		return Session{}, err
	}
	user, err := readUser(ctx, tx, userID)
	if err != nil {
		return Session{}, err
	}
	token := newToken()
	hash, _ := tokenHash(token)
	expires := now.Add(30 * 24 * time.Hour)
	if _, err = tx.Exec(ctx, "INSERT INTO sessions(id,user_id,token_hash,created_at,expires_at) VALUES($1,$2,$3,$4,$5)", identifier.New(), userID, hash, now, expires); err != nil {
		return Session{}, err
	}
	if _, err = tx.Exec(ctx, "UPDATE email_challenges SET consumed_at=$2,code_hmac=NULL,code_ciphertext=NULL WHERE id=$1", id, now); err != nil {
		return Session{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return Session{}, fmt.Errorf("commit login: %w", err)
	}
	return Session{AccessToken: token, TokenType: "Bearer", ExpiresAt: expires.UTC(), User: user}, nil
}
func (s *Service) Authenticate(ctx context.Context, token string) (Principal, error) {
	hash, err := tokenHash(token)
	if err != nil {
		return Principal{}, err
	}
	var p Principal
	err = s.pool.QueryRow(ctx, "SELECT user_id,id FROM sessions WHERE token_hash=$1 AND revoked_at IS NULL AND expires_at>clock_timestamp()", hash).Scan(&p.UserID, &p.SessionID)
	if errors.Is(err, pgx.ErrNoRows) {
		return Principal{}, apperror.New("UNAUTHENTICATED")
	}
	if err != nil {
		return Principal{}, fmt.Errorf("authenticate session: %w", err)
	}
	return p, nil
}
func (s *Service) Logout(ctx context.Context, p Principal) error {
	_, err := s.pool.Exec(ctx, "UPDATE sessions SET revoked_at=clock_timestamp() WHERE id=$1 AND user_id=$2 AND revoked_at IS NULL", p.SessionID, p.UserID)
	if err != nil {
		return fmt.Errorf("revoke session: %w", err)
	}
	return nil
}
