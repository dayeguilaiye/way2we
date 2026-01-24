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
	"github.com/way2we/way2we_api/ent/useridentity"
	pkgjwt "github.com/way2we/way2we_api/internal/pkg/jwt"
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
// Service handles authentication-related operations.
type Service struct {
	client           *ent.Client // Database client
	smsProvider      SmsProvider
	emailProvider    EmailProvider
	blacklistService BlacklistService

	// In-memory storage for verification codes (MVP only)
	codes map[string]verificationEntry
	mu    sync.RWMutex

	// Configuration
	codeLength     int
	codeExpiration time.Duration

	// JWT Config
	jwtSecret string
	jwtExpiry time.Duration
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

// WithJWT sets the JWT secret and expiration.
func WithJWT(secret string, expiryHours int) ServiceOption {
	return func(s *Service) {
		s.jwtSecret = secret
		s.jwtExpiry = time.Duration(expiryHours) * time.Hour
	}
}

// WithBlacklistService sets the blacklist service.
func WithBlacklistService(blacklistService BlacklistService) ServiceOption {
	return func(s *Service) {
		s.blacklistService = blacklistService
	}
}

// NewService creates a new authentication service.
func NewService(client *ent.Client, smsProvider SmsProvider, emailProvider EmailProvider, opts ...ServiceOption) *Service {
	s := &Service{
		client:           client,
		smsProvider:      smsProvider,
		emailProvider:    emailProvider,
		blacklistService: NewDBBlacklistService(client), // Default to DB blacklist
		codes:            make(map[string]verificationEntry),
		codeLength:       6,               // Default: 6-digit code
		codeExpiration:   5 * time.Minute, // Default: 5 minutes
		jwtExpiry:        24 * time.Hour,  // Default: 24 hours
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

// AuthResult contains the authentication result.
type AuthResult struct {
	Token string    `json:"token"`
	User  *ent.User `json:"user"`
}

// Register creates a new user with password using a transaction.
func (s *Service) Register(ctx context.Context, verifyType VerificationType, target string, code string, password string) (*AuthResult, error) {
	// 1. Verify code
	if !s.VerifyCode(ctx, target, code) {
		return nil, errors.New("验证码无效或已过期")
	}

	// 2. Hash password
	hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("密码加密失败: %w", err)
	}

	// 3. Start Transaction
	tx, err := s.client.Tx(ctx)
	if err != nil {
		return nil, fmt.Errorf("starting transaction: %w", err)
	}

	// Determine identity type
	idType := useridentity.TypePhone
	if verifyType == VerificationTypeEmail {
		idType = useridentity.TypeEmail
	}

	// 4. Check if identity exists
	exists, err := tx.UserIdentity.Query().
		Where(
			useridentity.TypeEQ(idType),
			useridentity.IdentifierEQ(target),
		).
		Exist(ctx)
	if err != nil {
		tx.Rollback()
		return nil, err
	}
	if exists {
		tx.Rollback()
		return nil, errors.New("该账号已注册")
	}

	// 5. Create User
	u, err := tx.User.Create().
		SetPasswordHash(string(hashed)).
		SetNickname(target). // Set default nickname as target (masked in real logic usually)
		Save(ctx)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("creating user: %w", err)
	}

	// 6. Create UserIdentity
	_, err = tx.UserIdentity.Create().
		SetType(idType).
		SetIdentifier(target).
		SetVerified(true). // Verified via code
		SetUser(u).
		Save(ctx)
	if err != nil {
		tx.Rollback()
		return nil, fmt.Errorf("creating identity: %w", err)
	}

	// 7. Commit Transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("committing transaction: %w", err)
	}

	// 8. Generate Token
	token, err := pkgjwt.GenerateToken(u.ID, s.jwtSecret, s.jwtExpiry)
	if err != nil {
		return nil, fmt.Errorf("generating token: %w", err)
	}

	return &AuthResult{
		Token: token,
		User:  u,
	}, nil
}

// LoginByPassword authenticates a user using password.
func (s *Service) LoginByPassword(ctx context.Context, verifyType VerificationType, target string, password string) (*AuthResult, error) {
	// 1. Determine identity type
	idType := useridentity.TypePhone
	if verifyType == VerificationTypeEmail {
		idType = useridentity.TypeEmail
	}

	// 2. Find Identity
	identity, err := s.client.UserIdentity.Query().
		Where(
			useridentity.TypeEQ(idType),
			useridentity.IdentifierEQ(target),
		).
		WithUser(). // Eager load user
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, errors.New("用户不存在")
		}
		return nil, err
	}

	// 3. Get User
	u := identity.Edges.User
	if u == nil {
		return nil, errors.New("用户数据异常")
	}

	// 4. Verify Password
	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password)); err != nil {
		return nil, errors.New("密码错误")
	}

	// 5. Generate Token
	token, err := pkgjwt.GenerateToken(u.ID, s.jwtSecret, s.jwtExpiry)
	if err != nil {
		return nil, fmt.Errorf("generating token: %w", err)
	}

	return &AuthResult{
		Token: token,
		User:  u,
	}, nil
}

// LoginByCode authenticates a user using verification code.
func (s *Service) LoginByCode(ctx context.Context, verifyType VerificationType, target string, code string) (*AuthResult, error) {
	// 1. Verify Code
	if !s.VerifyCode(ctx, target, code) {
		return nil, errors.New("验证码无效或已过期")
	}

	// 2. Determine identity type
	idType := useridentity.TypePhone
	if verifyType == VerificationTypeEmail {
		idType = useridentity.TypeEmail
	}

	// 3. Find Identity
	identity, err := s.client.UserIdentity.Query().
		Where(
			useridentity.TypeEQ(idType),
			useridentity.IdentifierEQ(target),
		).
		WithUser().
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, errors.New("用户不存在，请先注册")
		}
		return nil, err
	}

	// 4. Get User
	u := identity.Edges.User
	if u == nil {
		return nil, errors.New("用户数据异常")
	}

	// 5. Generate Token
	token, err := pkgjwt.GenerateToken(u.ID, s.jwtSecret, s.jwtExpiry)
	if err != nil {
		return nil, fmt.Errorf("generating token: %w", err)
	}

	return &AuthResult{
		Token: token,
		User:  u,
	}, nil
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

// Logout invalidates the given token by adding it to the blacklist.
func (s *Service) Logout(ctx context.Context, token string) error {
	// Parse the token to get expiration time
	claims, err := pkgjwt.ParseToken(token, s.jwtSecret)
	if err != nil {
		// Even if token is invalid/expired, we don't return error
		// (user is effectively logged out)
		return nil
	}

	// Add to blacklist with token's expiration time
	expiresAt := claims.ExpiresAt.Time
	return s.blacklistService.AddToBlacklist(ctx, token, expiresAt)
}

// IsTokenBlacklisted checks if a token is in the blacklist.
func (s *Service) IsTokenBlacklisted(ctx context.Context, token string) (bool, error) {
	return s.blacklistService.IsBlacklisted(ctx, token)
}

// GetJWTSecret returns the JWT secret for middleware use.
func (s *Service) GetJWTSecret() string {
	return s.jwtSecret
}
