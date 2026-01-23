package auth

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"os"
	"sync"
	"time"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/user"
	"golang.org/x/crypto/bcrypt"
)

// VerificationType represents the type of verification (phone or email).
type VerificationType string

const (
	// VerificationTypePhone indicates phone number verification.
	VerificationTypePhone VerificationType = "phone"
	// VerificationTypeEmail indicates email verification.
	VerificationTypeEmail VerificationType = "email"
)

// verificationEntry stores a verification code with its expiration time.
type verificationEntry struct {
	Code      string
	ExpiresAt time.Time
}

// Service handles authentication-related operations.
type Service struct {
	client        *ent.Client // Database client
	smsProvider   SmsProvider
	emailProvider EmailProvider

	// In-memory storage for verification codes (MVP only)
	// In production, this should be replaced with Redis or similar
	codes map[string]verificationEntry
	mu    sync.RWMutex

	// Configuration
	codeLength     int
	codeExpiration time.Duration
}

// ServiceOption allows optional configuration of the Service.
type ServiceOption func(*Service)

// WithCodeLength sets the length of generated verification codes.
func WithCodeLength(length int) ServiceOption {
	return func(s *Service) {
		s.codeLength = length
	}
}

// WithCodeExpiration sets the expiration duration for verification codes.
func WithCodeExpiration(duration time.Duration) ServiceOption {
	return func(s *Service) {
		s.codeExpiration = duration
	}
}

// NewService creates a new authentication service.
func NewService(client *ent.Client, smsProvider SmsProvider, emailProvider EmailProvider, opts ...ServiceOption) *Service {
	s := &Service{
		client:         client,
		smsProvider:    smsProvider,
		emailProvider:  emailProvider,
		codes:          make(map[string]verificationEntry),
		codeLength:     6,               // Default: 6-digit code
		codeExpiration: 5 * time.Minute, // Default: 5 minutes
	}

	for _, opt := range opts {
		opt(s)
	}

	return s
}

// SendVerificationCode generates and sends a verification code to the target.
// target is either a phone number or email address depending on the verification type.
func (s *Service) SendVerificationCode(ctx context.Context, verifyType VerificationType, target string) error {
	// Generate 6-digit random code
	code, err := s.generateCode()
	if err != nil {
		return fmt.Errorf("failed to generate verification code: %w", err)
	}

	// Store the code with expiration
	s.storeCode(target, code)

	// Send the code via appropriate provider
	switch verifyType {
	case VerificationTypePhone:
		if s.smsProvider == nil {
			return fmt.Errorf("SMS provider not configured")
		}
		return s.smsProvider.Send(ctx, target, code)
	case VerificationTypeEmail:
		if s.emailProvider == nil {
			return fmt.Errorf("Email provider not configured")
		}
		return s.emailProvider.Send(ctx, target, code)
	default:
		return fmt.Errorf("unsupported verification type: %s", verifyType)
	}
}

// VerifyCode checks if the provided code is valid for the target.
// Returns true if the code is valid (matches stored code or magic code).
// Returns false if the code is invalid or expired.
func (s *Service) VerifyCode(ctx context.Context, target string, code string) bool {
	// Check magic code first (from environment variable)
	magicCode := os.Getenv("AUTH_MAGIC_CODE")
	if magicCode != "" && code == magicCode {
		return true
	}

	// Check stored code
	s.mu.RLock()
	entry, exists := s.codes[target]
	s.mu.RUnlock()

	if !exists {
		return false
	}

	// Check if code has expired
	if time.Now().After(entry.ExpiresAt) {
		// Clean up expired code
		s.mu.Lock()
		delete(s.codes, target)
		s.mu.Unlock()
		return false
	}

	// Verify code matches
	if entry.Code == code {
		// Remove used code (one-time use)
		s.mu.Lock()
		delete(s.codes, target)
		s.mu.Unlock()
		return true
	}

	return false
}

// Register creates a new user with password.
func (s *Service) Register(ctx context.Context, verifyType VerificationType, target string, code string, password string) (*ent.User, error) {
	// 1. Verify code
	if !s.VerifyCode(ctx, target, code) {
		return nil, errors.New("验证码无效或已过期")
	}

	// 2. Hash password
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("密码加密失败: %w", err)
	}

	// 3. Check if user exists (optional, database unique constraint handles it but better err msg here)
	// We rely on DB constraint for now to keep it simple or check explicitly
	// For MVP, letting DB error is fine, or we can check:
	// exists, _ := s.client.User.Query().Where(user.Email(target)).Exist(ctx)

	// 4. Create user
	builder := s.client.User.Create().
		SetPasswordHash(string(hashed)).
		SetNickname(target) // Set default nickname as target

	if verifyType == VerificationTypeEmail {
		builder.SetEmail(target)
	} else {
		builder.SetPhone(target)
	}

	user, err := builder.Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return nil, errors.New("用户已存在")
		}
		return nil, fmt.Errorf("创建用户失败: %w", err)
	}

	return user, nil
}

// LoginByPassword authenticates a user using password.
func (s *Service) LoginByPassword(ctx context.Context, verifyType VerificationType, target string, password string) (*ent.User, error) {
	// 1. Find user
	q := s.client.User.Query()
	if verifyType == VerificationTypeEmail {
		q.Where(user.Email(target))
	} else {
		q.Where(user.Phone(target))
	}

	u, err := q.Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, errors.New("用户不存在")
		}
		return nil, err
	}

	// 2. Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password)); err != nil {
		return nil, errors.New("密码错误")
	}

	return u, nil
}

// LoginByCode authenticates a user using verification code.
// For MVP, this might just login user if exists, or do we allow auto-register?
// PRD said "Register: set password". "Login: code or password".
// So LoginByCode implies checking if user exists, if so, login.
func (s *Service) LoginByCode(ctx context.Context, verifyType VerificationType, target string, code string) (*ent.User, error) {
	// 1. Verify Code
	if !s.VerifyCode(ctx, target, code) {
		return nil, errors.New("验证码无效或已过期")
	}

	// 2. Find User
	q := s.client.User.Query()
	if verifyType == VerificationTypeEmail {
		q.Where(user.Email(target))
	} else {
		q.Where(user.Phone(target))
	}

	u, err := q.Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, errors.New("用户不存在，请先注册")
		}
		return nil, err
	}

	return u, nil
}

// generateCode generates a cryptographically secure random n-digit code.
func (s *Service) generateCode() (string, error) {
	// Calculate max value: 10^n - 1 (e.g., 999999 for 6 digits)
	max := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(s.codeLength)), nil)

	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}

	// Format with leading zeros
	format := fmt.Sprintf("%%0%dd", s.codeLength)
	return fmt.Sprintf(format, n.Int64()), nil
}

// storeCode stores a verification code for the target with expiration.
func (s *Service) storeCode(target string, code string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.codes[target] = verificationEntry{
		Code:      code,
		ExpiresAt: time.Now().Add(s.codeExpiration),
	}
}

// CleanupExpiredCodes removes expired codes from storage.
// This should be called periodically in production.
func (s *Service) CleanupExpiredCodes() {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now()
	for target, entry := range s.codes {
		if now.After(entry.ExpiresAt) {
			delete(s.codes, target)
		}
	}
}
