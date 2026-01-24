package auth

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"time"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/tokenblacklist"
)

// BlacklistService provides token blacklist operations.
type BlacklistService interface {
	// AddToBlacklist adds a token to the blacklist.
	AddToBlacklist(ctx context.Context, token string, expiresAt time.Time) error
	// IsBlacklisted checks if a token is in the blacklist.
	IsBlacklisted(ctx context.Context, token string) (bool, error)
	// CleanupExpiredTokens removes expired tokens from the blacklist.
	CleanupExpiredTokens(ctx context.Context) (int, error)
}

// DBBlacklistService implements BlacklistService using PostgreSQL.
type DBBlacklistService struct {
	client *ent.Client
}

// NewDBBlacklistService creates a new database-backed blacklist service.
func NewDBBlacklistService(client *ent.Client) *DBBlacklistService {
	return &DBBlacklistService{client: client}
}

// hashToken creates a SHA256 hash of the token for secure storage.
func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

// AddToBlacklist adds a token to the blacklist.
func (s *DBBlacklistService) AddToBlacklist(ctx context.Context, token string, expiresAt time.Time) error {
	tokenHash := hashToken(token)

	// Check if already blacklisted
	exists, err := s.client.TokenBlacklist.Query().
		Where(tokenblacklist.TokenHashEQ(tokenHash)).
		Exist(ctx)
	if err != nil {
		return err
	}
	if exists {
		return nil // Already blacklisted, no-op
	}

	// Create new blacklist entry
	_, err = s.client.TokenBlacklist.Create().
		SetTokenHash(tokenHash).
		SetExpiresAt(expiresAt).
		Save(ctx)

	return err
}

// IsBlacklisted checks if a token is in the blacklist.
func (s *DBBlacklistService) IsBlacklisted(ctx context.Context, token string) (bool, error) {
	tokenHash := hashToken(token)

	exists, err := s.client.TokenBlacklist.Query().
		Where(tokenblacklist.TokenHashEQ(tokenHash)).
		Exist(ctx)

	if err != nil {
		return false, err
	}

	return exists, nil
}

// CleanupExpiredTokens removes expired tokens from the blacklist.
// Returns the number of deleted tokens.
func (s *DBBlacklistService) CleanupExpiredTokens(ctx context.Context) (int, error) {
	deleted, err := s.client.TokenBlacklist.Delete().
		Where(tokenblacklist.ExpiresAtLT(time.Now())).
		Exec(ctx)

	return deleted, err
}
