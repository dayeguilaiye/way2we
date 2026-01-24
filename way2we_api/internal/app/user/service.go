package user

import (
	"context"
	"errors"
	"fmt"

	"github.com/way2we/way2we_api/ent"
)

// Predefined errors for structured error handling
var (
	ErrNicknameTooLong = errors.New("nickname cannot exceed 20 characters")
	ErrUserNotFound    = errors.New("user not found")
	ErrUpdateFailed    = errors.New("failed to update profile")
)

type Service struct {
	client *ent.Client
}

func NewService(client *ent.Client) *Service {
	return &Service{client: client}
}

func (s *Service) UpdateProfile(ctx context.Context, userID int, nickname *string, avatar *string) (*ent.User, error) {
	update := s.client.User.UpdateOneID(userID)

	if nickname != nil {
		if len(*nickname) > 20 {
			return nil, ErrNicknameTooLong
		}
		update.SetNickname(*nickname)
	}

	if avatar != nil {
		update.SetAvatar(*avatar)
	}

	u, err := update.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUpdateFailed, err)
	}

	return u, nil
}

func (s *Service) GetProfile(ctx context.Context, userID int) (*ent.User, error) {
	u, err := s.client.User.Get(ctx, userID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get profile: %w", err)
	}
	return u, nil
}
