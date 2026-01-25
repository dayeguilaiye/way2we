package group

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/user"
)

// Predefined errors for structured error handling
var (
	ErrGroupNameEmpty    = errors.New("group name cannot be empty")
	ErrGroupNameTooLong  = errors.New("group name cannot exceed 30 characters")
	ErrGroupNotFound     = errors.New("group not found")
	ErrCreateGroupFailed = errors.New("failed to create group")
	ErrUserNotFound      = errors.New("user not found")
)

// Service handles group-related business logic.
type Service struct {
	client *ent.Client
}

// NewService creates a new group service.
func NewService(client *ent.Client) *Service {
	return &Service{client: client}
}

// CreateGroupResult contains the result of creating a group.
type CreateGroupResult struct {
	Group  *ent.Group
	Member *ent.GroupMember
}

// CreateGroup creates a new group and adds the creator as admin.
// This operation is transactional.
func (s *Service) CreateGroup(ctx context.Context, userID int, name string) (*CreateGroupResult, error) {
	// Trim and validate input
	name = strings.TrimSpace(name)
	if name == "" {
		return nil, ErrGroupNameEmpty
	}
	if len(name) > 30 {
		return nil, ErrGroupNameTooLong
	}

	// Verify the specific user exists
	userExists, err := s.client.User.Query().Where(user.ID(userID)).Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: failed to check user existence", ErrCreateGroupFailed)
	}
	if !userExists {
		return nil, ErrUserNotFound
	}

	// Use transaction to ensure atomicity
	tx, err := s.client.Tx(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: failed to start transaction: %v", ErrCreateGroupFailed, err)
	}

	// Create the group
	group, err := tx.Group.Create().
		SetName(name).
		Save(ctx)
	if err != nil {
		_ = tx.Rollback()
		return nil, fmt.Errorf("%w: %v", ErrCreateGroupFailed, err)
	}

	// Add creator as admin member
	member, err := tx.GroupMember.Create().
		SetUserID(userID).
		SetGroupID(group.ID).
		SetRole(groupmember.RoleAdmin).
		Save(ctx)
	if err != nil {
		_ = tx.Rollback()
		return nil, fmt.Errorf("%w: failed to add creator as admin: %v", ErrCreateGroupFailed, err)
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("%w: failed to commit transaction: %v", ErrCreateGroupFailed, err)
	}

	return &CreateGroupResult{
		Group:  group,
		Member: member,
	}, nil
}

// GetGroup retrieves a group by ID.
func (s *Service) GetGroup(ctx context.Context, groupID int) (*ent.Group, error) {
	group, err := s.client.Group.Get(ctx, groupID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrGroupNotFound
		}
		return nil, fmt.Errorf("failed to get group: %w", err)
	}
	return group, nil
}
