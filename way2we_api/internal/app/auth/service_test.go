package auth_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/internal/app/auth"
)

// mockSmsProvider is a test double for SmsProvider
type mockSmsProvider struct {
	lastPhone string
	lastCode  string
	sendErr   error
}

func (m *mockSmsProvider) Send(ctx context.Context, phone string, code string) error {
	m.lastPhone = phone
	m.lastCode = code
	return m.sendErr
}

// mockEmailProvider is a test double for EmailProvider
type mockEmailProvider struct {
	lastEmail string
	lastCode  string
	sendErr   error
}

func (m *mockEmailProvider) Send(ctx context.Context, email string, code string) error {
	m.lastEmail = email
	m.lastCode = code
	return m.sendErr
}

func TestService_SendVerificationCode_Phone(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()
	err := service.SendVerificationCode(ctx, auth.VerificationTypePhone, "13800138000")

	require.NoError(t, err)
	assert.Equal(t, "13800138000", smsProvider.lastPhone)
	assert.Len(t, smsProvider.lastCode, 6)
}

func TestService_SendVerificationCode_Email(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()
	err := service.SendVerificationCode(ctx, auth.VerificationTypeEmail, "test@example.com")

	require.NoError(t, err)
	assert.Equal(t, "test@example.com", emailProvider.lastEmail)
	assert.Len(t, emailProvider.lastCode, 6)
}

func TestService_VerifyCode_ValidCode(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()
	target := "13800138000"

	// Send code first
	err := service.SendVerificationCode(ctx, auth.VerificationTypePhone, target)
	require.NoError(t, err)

	// Get the code that was sent
	code := smsProvider.lastCode

	// Verify should succeed
	valid := service.VerifyCode(ctx, target, code)
	assert.True(t, valid, "Valid code should be accepted")

	// Same code should not work again (one-time use)
	valid = service.VerifyCode(ctx, target, code)
	assert.False(t, valid, "Code should only be usable once")
}

func TestService_VerifyCode_InvalidCode(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()
	target := "13800138000"

	// Send code first
	err := service.SendVerificationCode(ctx, auth.VerificationTypePhone, target)
	require.NoError(t, err)

	// Verify with wrong code should fail
	valid := service.VerifyCode(ctx, target, "000000")
	assert.False(t, valid, "Invalid code should be rejected")
}

func TestService_VerifyCode_MagicCode(t *testing.T) {
	// Set magic code environment variable
	os.Setenv("AUTH_MAGIC_CODE", "123456")
	defer os.Unsetenv("AUTH_MAGIC_CODE")

	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()
	target := "13800138000"

	// Magic code should work even without sending a real code
	valid := service.VerifyCode(ctx, target, "123456")
	assert.True(t, valid, "Magic code should be accepted")
}

func TestService_VerifyCode_NoStoredCode(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()

	// Verify without sending first should fail
	valid := service.VerifyCode(ctx, "13800138000", "123456")
	assert.False(t, valid, "Non-existent target should be rejected")
}

func TestService_VerifyCode_ExpiredCode(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	// Create service with very short expiration
	service := auth.NewService(nil, smsProvider, emailProvider, auth.WithCodeExpiration(1*time.Millisecond))

	ctx := context.Background()
	target := "13800138000"

	// Send code first
	err := service.SendVerificationCode(ctx, auth.VerificationTypePhone, target)
	require.NoError(t, err)

	code := smsProvider.lastCode

	// Wait for expiration
	time.Sleep(10 * time.Millisecond)

	// Verify should fail due to expiration
	valid := service.VerifyCode(ctx, target, code)
	assert.False(t, valid, "Expired code should be rejected")
}

func TestService_GeneratedCodeFormat(t *testing.T) {
	smsProvider := &mockSmsProvider{}
	emailProvider := &mockEmailProvider{}
	service := auth.NewService(nil, smsProvider, emailProvider)

	ctx := context.Background()

	// Generate multiple codes and check format
	for i := 0; i < 10; i++ {
		err := service.SendVerificationCode(ctx, auth.VerificationTypePhone, "13800138000")
		require.NoError(t, err)

		code := smsProvider.lastCode
		assert.Len(t, code, 6, "Code should be 6 digits")

		// Check all characters are digits
		for _, c := range code {
			assert.True(t, c >= '0' && c <= '9', "Code should only contain digits")
		}
	}
}
