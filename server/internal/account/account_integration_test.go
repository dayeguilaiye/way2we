//go:build integration

package account

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
	"way2we/server/internal/platform/testdb"
)

type inbox struct {
	mail CodeMail
	fail bool
}

func (i *inbox) SendCode(_ context.Context, m CodeMail) error {
	i.mail = m
	if i.fail {
		return fmt.Errorf("injected delivery failure")
	}
	return nil
}
func fixture(t *testing.T) (*Service, *pgxpool.Pool, *inbox) {
	t.Helper()
	p := testdb.New(t)
	i := &inbox{}
	s, err := New(p, bytes.Repeat([]byte{7}, 32), i)
	if err != nil {
		t.Fatal(err)
	}
	return s, p, i
}
func codeOf(err error) string {
	var e *apperror.Error
	if errors.As(err, &e) {
		return e.Code
	}
	return ""
}
func request(t *testing.T, s *Service, i *inbox, email string) string {
	t.Helper()
	if _, err := s.RequestCode(t.Context(), email, email, identifier.New()); err != nil {
		t.Fatal(err)
	}
	if ok, err := s.DeliverOne(t.Context()); !ok || err != nil {
		t.Fatalf("delivery: %v", err)
	}
	return i.mail.Code
}
func execSQL(t *testing.T, p *pgxpool.Pool, sql string, args ...any) {
	t.Helper()
	if _, err := p.Exec(t.Context(), sql, args...); err != nil {
		t.Fatal(err)
	}
}
func TestAccountRecoveryConsumptionAndProfile(t *testing.T) {
	s, p, i := fixture(t)
	ctx := t.Context()
	email := "person+tag@example.test"
	code := request(t, s, i, " Person+Tag@Example.TEST ")
	var wins []Session
	var mutex sync.Mutex
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() {
			result, err := s.Login(ctx, email, code, "peer")
			if err == nil {
				mutex.Lock()
				wins = append(wins, result)
				mutex.Unlock()
			} else if codeOf(err) != "CODE_INVALID_OR_EXPIRED" {
				t.Errorf("concurrent login: %v", err)
			}
		})
	}
	wg.Wait()
	if len(wins) != 1 {
		t.Fatalf("login succeeded %d times", len(wins))
	}
	first := wins[0]
	principal, err := s.Authenticate(ctx, first.AccessToken)
	if err != nil {
		t.Fatal(err)
	}
	name, theme := "阿禾", "celadon"
	key := identifier.New()
	change := ProfileUpdate{DisplayName: &name, Theme: &theme}
	saved, err := s.Update(ctx, principal, key, change)
	if err != nil || saved.DisplayName != name || saved.Theme != theme {
		t.Fatalf("save profile: %v", err)
	}
	name2 := "小禾"
	if _, err = s.Update(ctx, principal, identifier.New(), ProfileUpdate{DisplayName: &name2}); err != nil {
		t.Fatal(err)
	}
	replay, err := s.Update(ctx, principal, key, change)
	if err != nil || replay.DisplayName != name {
		t.Fatal("profile replay must return original snapshot")
	}
	if _, err = s.Update(ctx, principal, key, ProfileUpdate{DisplayName: &name2}); codeOf(err) != "IDEMPOTENCY_KEY_REUSED" {
		t.Fatal("key reuse allowed")
	}
	current, err := s.Me(ctx, principal)
	if err != nil || current.DisplayName != name2 {
		t.Fatal("replay changed profile")
	}
	execSQL(t, p, "UPDATE email_challenges SET created_at=created_at-interval '61 seconds'")
	code = request(t, s, i, email)
	second, err := s.Login(ctx, email, code, "peer2")
	if err != nil || second.User.ID != first.User.ID || second.User.Theme != theme || second.User.DisplayName != name2 {
		t.Fatalf("account recovery: %v", err)
	}
	if err = s.Logout(ctx, principal); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Authenticate(ctx, first.AccessToken); codeOf(err) != "UNAUTHENTICATED" {
		t.Fatal("revoked session usable")
	}
	if _, err = s.Authenticate(ctx, second.AccessToken); err != nil {
		t.Fatal("other device revoked")
	}
	if _, err = s.Update(ctx, principal, key, change); codeOf(err) != "UNAUTHENTICATED" {
		t.Fatal("replay bypassed revocation")
	}
	execSQL(t, p, "UPDATE sessions SET expires_at=clock_timestamp()-interval '1 second'")
	if _, err = s.Authenticate(ctx, second.AccessToken); codeOf(err) != "UNAUTHENTICATED" {
		t.Fatal("expired session usable")
	}
	var secrets int
	if err = p.QueryRow(ctx, "SELECT count(*) FROM email_challenges WHERE code_hmac IS NOT NULL OR code_ciphertext IS NOT NULL").Scan(&secrets); err != nil || secrets != 0 {
		t.Fatal("consumed challenge retained secrets")
	}
}
func TestCodeLimitsExpiryResendAndDeliveryRecovery(t *testing.T) {
	s, p, i := fixture(t)
	ctx := t.Context()
	email := "limits@example.test"
	code := request(t, s, i, email)
	if _, err := s.RequestCode(ctx, email, "peer", identifier.New()); codeOf(err) != "RATE_LIMITED" {
		t.Fatal("resend interval missing")
	}
	wrong := "000000"
	if wrong == code {
		wrong = "111111"
	}
	for range 5 {
		if _, err := s.Login(ctx, email, wrong, "peer"); codeOf(err) != "CODE_INVALID_OR_EXPIRED" {
			t.Fatal("bad code accepted")
		}
	}
	if _, err := s.Login(ctx, email, code, "peer"); codeOf(err) != "CODE_INVALID_OR_EXPIRED" {
		t.Fatal("attempt cap missing")
	}
	execSQL(t, p, "UPDATE email_challenges SET created_at=created_at-interval '61 seconds'")
	code = request(t, s, i, email)
	execSQL(t, p, "UPDATE email_challenges SET expires_at=clock_timestamp()-interval '1 second'")
	if _, err := s.Login(ctx, email, code, "peer"); codeOf(err) != "CODE_INVALID_OR_EXPIRED" {
		t.Fatal("expiry missing")
	}
	execSQL(t, p, "UPDATE email_challenges SET created_at=created_at-interval '61 seconds'")
	code = request(t, s, i, email)
	execSQL(t, p, "UPDATE email_challenges SET created_at=created_at-interval '61 seconds'")
	if _, err := s.RequestCode(ctx, email, "peer", identifier.New()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Login(ctx, email, code, "peer"); codeOf(err) != "CODE_INVALID_OR_EXPIRED" {
		t.Fatal("resend kept old code")
	}
	i.fail = true
	if _, err := s.DeliverOne(ctx); err == nil {
		t.Fatal("expected send failure")
	}
	job := i.mail
	execSQL(t, p, "UPDATE email_challenges SET available_at=clock_timestamp() WHERE delivery_state='pending'")
	restarted, err := New(p, s.key, i)
	if err != nil {
		t.Fatal(err)
	}
	i.fail = false
	if ok, err := restarted.DeliverOne(ctx); !ok || err != nil {
		t.Fatal("restart did not retry")
	}
	if i.mail != job {
		t.Fatal("retry changed challenge")
	}
	if _, err := s.Login(ctx, email, i.mail.Code, "peer"); err != nil {
		t.Fatal(err)
	}
}
func TestPersistedDeliveryIsEncryptedAndSourceRateLimited(t *testing.T) {
	s, p, i := fixture(t)
	ctx := t.Context()
	for n := range 20 {
		if _, err := s.RequestCode(ctx, fmt.Sprintf("u%d@example.test", n), "peer", identifier.New()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := s.RequestCode(ctx, "blocked@example.test", "peer", identifier.New()); codeOf(err) != "RATE_LIMITED" {
		t.Fatal("source limit missing")
	}
	var id string
	var encrypted, digest []byte
	if err := p.QueryRow(ctx, "SELECT id,code_ciphertext,code_hmac FROM email_challenges ORDER BY available_at,id LIMIT 1").Scan(&id, &encrypted, &digest); err != nil {
		t.Fatal(err)
	}
	code, err := s.open(id, encrypted)
	if err != nil || len(code) != 6 || len(digest) != 32 || bytes.Contains(encrypted, []byte(code)) {
		t.Fatal("invalid encrypted challenge")
	}
	if _, err = s.open(identifier.New(), encrypted); err == nil {
		t.Fatal("ciphertext not bound to challenge")
	}
	// A worker crash after claiming is recovered only after its lease expires.
	execSQL(t, p, "UPDATE email_challenges SET delivery_state='sending',lease_until=clock_timestamp()-interval '1 second',lease_token=$1 WHERE id=$2", identifier.New(), id)
	if ok, err := s.DeliverOne(ctx); !ok || err != nil || i.mail.ID != id {
		t.Fatal("expired lease not recovered")
	}
}

func TestCleanupClearsExpiredChallengeMaterial(t *testing.T) {
	s, p, _ := fixture(t)
	if _, err := s.RequestCode(t.Context(), "expired@example.test", "peer", identifier.New()); err != nil {
		t.Fatal(err)
	}
	execSQL(t, p, "UPDATE email_challenges SET expires_at=clock_timestamp()-interval '1 second'")
	if err := s.cleanup(t.Context()); err != nil {
		t.Fatal(err)
	}
	var empty bool
	var state string
	if err := p.QueryRow(t.Context(), "SELECT code_hmac IS NULL AND code_ciphertext IS NULL,delivery_state FROM email_challenges").Scan(&empty, &state); err != nil || !empty || state != "expired" {
		t.Fatal("expired material retained")
	}
	execSQL(t, p, "UPDATE email_challenges SET expires_at=clock_timestamp()-interval '2 days'")
	if err := s.cleanup(t.Context()); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := p.QueryRow(t.Context(), "SELECT count(*) FROM email_challenges").Scan(&count); err != nil || count != 0 {
		t.Fatal("expired metadata retained beyond policy")
	}
}
