// Package account owns email challenges, stable identities and revocable sessions.
package account

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"math/big"
	"net/mail"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"way2we/server/internal/platform/apperror"
)

type User struct {
	ID          string    `json:"id"`
	DisplayName string    `json:"display_name"`
	Theme       string    `json:"theme"`
	CreatedAt   time.Time `json:"created_at"`
}
type Session struct {
	AccessToken string    `json:"access_token"`
	TokenType   string    `json:"token_type"`
	ExpiresAt   time.Time `json:"expires_at"`
	User        User      `json:"user"`
}
type Principal struct{ UserID, SessionID string }
type Accepted struct {
	ResendAfter int `json:"resend_after_seconds"`
	ExpiresIn   int `json:"expires_in_seconds"`
}
type CodeMail struct{ ID, Email, Code string }
type Sender interface {
	SendCode(context.Context, CodeMail) error
}
type Service struct {
	pool   *pgxpool.Pool
	key    []byte
	aead   cipher.AEAD
	sender Sender
	limits Limits
}

// Limits are fixed-window request budgets; resend interval and challenge attempts
// remain part of the shared login contract.
type Limits struct{ SendPerEmail, SendPerSource, VerifyPerSource int }

func DefaultLimits() Limits { return Limits{SendPerEmail: 5, SendPerSource: 20, VerifyPerSource: 60} }

func New(pool *pgxpool.Pool, key []byte, sender Sender) (*Service, error) {
	return NewWithLimits(pool, key, sender, DefaultLimits())
}
func NewWithLimits(pool *pgxpool.Pool, key []byte, sender Sender, limits Limits) (*Service, error) {
	if limits.SendPerEmail < 1 || limits.SendPerSource < 1 || limits.VerifyPerSource < 1 {
		return nil, fmt.Errorf("auth limits must be positive")
	}
	if len(key) != 32 || sender == nil {
		return nil, fmt.Errorf("account requires a 32-byte secret and mail sender")
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}
	return &Service{pool: pool, key: append([]byte(nil), key...), aead: aead, sender: sender, limits: limits}, nil
}
func NormalizeEmail(raw string) (string, error) {
	email := strings.ToLower(strings.TrimSpace(raw))
	for _, c := range email {
		if c < 33 || c > 126 {
			return "", fieldError("email", "INVALID_EMAIL")
		}
	}
	parsed, err := mail.ParseAddress(email)
	if err != nil || parsed.Address != email || len(email) > 254 || !strings.Contains(email, "@") || strings.ContainsAny(email, "<>\r\n") {
		return "", fieldError("email", "INVALID_EMAIL")
	}
	return email, nil
}
func fieldError(field, code string) error {
	return &apperror.Error{Code: "VALIDATION_FAILED", Fields: []apperror.Field{{Field: field, Code: code}}}
}
func (s *Service) digest(parts ...string) []byte {
	h := hmac.New(sha256.New, s.key)
	for _, p := range parts {
		h.Write([]byte(p))
		h.Write([]byte{0})
	}
	return h.Sum(nil)
}
func (s *Service) seal(id, code string) []byte {
	nonce := make([]byte, s.aead.NonceSize())
	rand.Read(nonce)
	return s.aead.Seal(nonce, nonce, []byte(code), []byte(id))
}
func (s *Service) open(id string, data []byte) (string, error) {
	n := s.aead.NonceSize()
	if len(data) < n {
		return "", fmt.Errorf("challenge ciphertext missing")
	}
	plain, err := s.aead.Open(nil, data[:n], data[n:], []byte(id))
	return string(plain), err
}
func rollback(tx pgx.Tx) {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	_ = tx.Rollback(ctx)
}
func lock(ctx context.Context, tx pgx.Tx, value []byte) error {
	_, err := tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", int64(binary.BigEndian.Uint64(value[:8])))
	return err
}
func (s *Service) rate(ctx context.Context, tx pgx.Tx, kind, value string, now time.Time, period time.Duration, maximum int) error {
	window := now.UTC().Truncate(period)
	bucket := s.digest("rate", kind, value, window.Format(time.RFC3339))
	var n int
	err := tx.QueryRow(ctx, `INSERT INTO auth_limits(bucket,attempts,expires_at) VALUES($1,1,$2) ON CONFLICT(bucket) DO UPDATE SET attempts=auth_limits.attempts+1 RETURNING attempts`, bucket, window.Add(period)).Scan(&n)
	if err != nil {
		return fmt.Errorf("count authentication attempts: %w", err)
	}
	if n > maximum {
		return apperror.New("RATE_LIMITED")
	}
	return nil
}
func newCode() string {
	n, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		panic("random unavailable")
	}
	return fmt.Sprintf("%06d", n.Int64())
}
func newToken() string {
	value := make([]byte, 32)
	rand.Read(value)
	return base64.RawURLEncoding.EncodeToString(value)
}
func tokenHash(token string) ([]byte, error) {
	value, err := base64.RawURLEncoding.DecodeString(token)
	if err != nil || len(value) != 32 {
		return nil, apperror.New("UNAUTHENTICATED")
	}
	sum := sha256.Sum256([]byte(token))
	return sum[:], nil
}
