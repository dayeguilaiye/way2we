package auth

import (
	"context"
	"testing"
	"time"

	_ "github.com/mattn/go-sqlite3"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
)

func TestDBBlacklistService_AddToBlacklist(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	blSvc := NewDBBlacklistService(client)
	ctx := context.Background()
	expiresAt := time.Now().Add(time.Hour)

	// Test adding token to blacklist
	err := blSvc.AddToBlacklist(ctx, "test-token-123", expiresAt)
	require.NoError(t, err)

	// Verify token is blacklisted
	blacklisted, err := blSvc.IsBlacklisted(ctx, "test-token-123")
	require.NoError(t, err)
	assert.True(t, blacklisted)

	// Test adding same token again (should be no-op)
	err = blSvc.AddToBlacklist(ctx, "test-token-123", expiresAt)
	require.NoError(t, err)
}

func TestDBBlacklistService_IsBlacklisted_NotBlacklisted(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	blSvc := NewDBBlacklistService(client)
	ctx := context.Background()

	// Test non-blacklisted token
	blacklisted, err := blSvc.IsBlacklisted(ctx, "nonexistent-token")
	require.NoError(t, err)
	assert.False(t, blacklisted)
}

func TestDBBlacklistService_CleanupExpiredTokens(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	blSvc := NewDBBlacklistService(client)
	ctx := context.Background()

	// Add expired token
	expiredTime := time.Now().Add(-time.Hour)
	err := blSvc.AddToBlacklist(ctx, "expired-token", expiredTime)
	require.NoError(t, err)

	// Add valid token
	validTime := time.Now().Add(time.Hour)
	err = blSvc.AddToBlacklist(ctx, "valid-token", validTime)
	require.NoError(t, err)

	// Cleanup expired tokens
	deleted, err := blSvc.CleanupExpiredTokens(ctx)
	require.NoError(t, err)
	assert.Equal(t, 1, deleted)

	// Verify expired token is removed but valid token remains
	blacklisted, err := blSvc.IsBlacklisted(ctx, "expired-token")
	require.NoError(t, err)
	assert.False(t, blacklisted)

	blacklisted, err = blSvc.IsBlacklisted(ctx, "valid-token")
	require.NoError(t, err)
	assert.True(t, blacklisted)
}

func TestService_Logout(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	smsProvider := NewMockSmsProvider()
	emailProvider := NewMockEmailProvider()

	svc := NewService(
		client,
		smsProvider,
		emailProvider,
		WithJWT("test-secret-key-for-testing", 24),
	)

	ctx := context.Background()

	// Register a user to get a valid token
	svc.storeCode("13800138000", "123456")
	result, err := svc.Register(ctx, VerificationTypePhone, "13800138000", "123456", "password123")
	require.NoError(t, err)
	require.NotEmpty(t, result.Token)

	// Verify token is not blacklisted initially
	blacklisted, err := svc.IsTokenBlacklisted(ctx, result.Token)
	require.NoError(t, err)
	assert.False(t, blacklisted)

	// Logout
	err = svc.Logout(ctx, result.Token)
	require.NoError(t, err)

	// Verify token is now blacklisted
	blacklisted, err = svc.IsTokenBlacklisted(ctx, result.Token)
	require.NoError(t, err)
	assert.True(t, blacklisted)
}

func TestService_Logout_InvalidToken(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	smsProvider := NewMockSmsProvider()
	emailProvider := NewMockEmailProvider()

	svc := NewService(
		client,
		smsProvider,
		emailProvider,
		WithJWT("test-secret-key-for-testing", 24),
	)

	ctx := context.Background()

	// Logout with invalid token should not return error
	err := svc.Logout(ctx, "invalid-token")
	require.NoError(t, err)
}

// Mock providers for testing
type MockSmsProvider struct {
	SentMessages []string
}

func NewMockSmsProvider() *MockSmsProvider {
	return &MockSmsProvider{}
}

func (m *MockSmsProvider) Send(ctx context.Context, phone, code string) error {
	m.SentMessages = append(m.SentMessages, phone+":"+code)
	return nil
}

type MockEmailProvider struct {
	SentMessages []string
}

func NewMockEmailProvider() *MockEmailProvider {
	return &MockEmailProvider{}
}

func (m *MockEmailProvider) Send(ctx context.Context, email, code string) error {
	m.SentMessages = append(m.SentMessages, email+":"+code)
	return nil
}
