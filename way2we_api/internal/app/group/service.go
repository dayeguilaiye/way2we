package group

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"strings"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/group"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/user"
)

// Predefined errors for structured error handling
var (
	ErrGroupNameEmpty         = errors.New("group name cannot be empty")
	ErrGroupNameTooLong       = errors.New("group name cannot exceed 30 characters")
	ErrGroupNotFound          = errors.New("group not found")
	ErrCreateGroupFailed      = errors.New("failed to create group")
	ErrUserNotFound           = errors.New("user not found")
	ErrInvitationCodeNotFound = errors.New("invitation code not found or invalid")
	ErrAlreadyMember          = errors.New("user is already a member of this group")
	ErrNotAdmin               = errors.New("user is not an admin of this group")
	ErrGenerateCodeFailed     = errors.New("failed to generate invitation code")
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

// Invitation code character set (avoid confusing characters like 0/O, 1/I/l)
const invitationCodeCharset = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"

// generateRandomCode generates a random 6-character invitation code
func generateRandomCode() (string, error) {
	bytes := make([]byte, 6)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	for i := range bytes {
		bytes[i] = invitationCodeCharset[int(bytes[i])%len(invitationCodeCharset)]
	}
	return string(bytes), nil
}

// GenerateInvitationCode generates a unique invitation code for the group.
// This is called automatically when creating a group.
func (s *Service) GenerateInvitationCode(ctx context.Context, groupID int) (string, error) {
	// Verify group exists
	_, err := s.client.Group.Get(ctx, groupID)
	if err != nil {
		if ent.IsNotFound(err) {
			return "", ErrGroupNotFound
		}
		return "", fmt.Errorf("failed to get group: %w", err)
	}

	// Try to generate a unique code (max 5 retries)
	for i := 0; i < 5; i++ {
		code, err := generateRandomCode()
		if err != nil {
			return "", fmt.Errorf("%w: %v", ErrGenerateCodeFailed, err)
		}

		// Try to update the group with this code
		err = s.client.Group.UpdateOneID(groupID).
			SetInvitationCode(code).
			Exec(ctx)
		if err != nil {
			// If unique constraint violation, retry
			if ent.IsConstraintError(err) {
				continue
			}
			return "", fmt.Errorf("%w: %v", ErrGenerateCodeFailed, err)
		}
		return code, nil
	}

	return "", fmt.Errorf("%w: max retries exceeded", ErrGenerateCodeFailed)
}

// GetInvitationCode retrieves the invitation code for a group.
// Only admins can view the invitation code.
func (s *Service) GetInvitationCode(ctx context.Context, groupID int, userID int) (string, error) {
	// Check if user is admin of the group
	isAdmin, err := s.isGroupAdmin(ctx, groupID, userID)
	if err != nil {
		return "", err
	}
	if !isAdmin {
		return "", ErrNotAdmin
	}

	// Get the group with its invitation code
	g, err := s.client.Group.Get(ctx, groupID)
	if err != nil {
		if ent.IsNotFound(err) {
			return "", ErrGroupNotFound
		}
		return "", fmt.Errorf("failed to get group: %w", err)
	}

	// If no code exists, generate one
	if g.InvitationCode == nil || *g.InvitationCode == "" {
		return s.GenerateInvitationCode(ctx, groupID)
	}

	return *g.InvitationCode, nil
}

// RefreshInvitationCode generates a new invitation code, invalidating the old one.
// Only admins can refresh the invitation code.
func (s *Service) RefreshInvitationCode(ctx context.Context, groupID int, userID int) (string, error) {
	// Check if user is admin of the group
	isAdmin, err := s.isGroupAdmin(ctx, groupID, userID)
	if err != nil {
		return "", err
	}
	if !isAdmin {
		return "", ErrNotAdmin
	}

	// Generate new code (this will overwrite the old one)
	return s.GenerateInvitationCode(ctx, groupID)
}

// GroupPreview contains basic group info for preview before joining.
type GroupPreview struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	MemberCount int    `json:"member_count"`
	CreatedAt   string `json:"created_at"`
}

// GetGroupByInvitation retrieves group info by invitation code.
// This is a public endpoint for previewing a group before joining.
func (s *Service) GetGroupByInvitation(ctx context.Context, code string) (*GroupPreview, error) {
	code = strings.TrimSpace(strings.ToUpper(code))
	if code == "" {
		return nil, ErrInvitationCodeNotFound
	}

	g, err := s.client.Group.Query().
		Where(group.InvitationCode(code)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrInvitationCodeNotFound
		}
		return nil, fmt.Errorf("failed to query group by invitation: %w", err)
	}

	// Count members
	memberCount, err := s.client.GroupMember.Query().
		Where(groupmember.GroupID(g.ID)).
		Count(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to count members: %w", err)
	}

	return &GroupPreview{
		ID:          g.ID,
		Name:        g.Name,
		MemberCount: memberCount,
		CreatedAt:   g.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}, nil
}

// JoinGroupResult contains the result of joining a group.
type JoinGroupResult struct {
	Group       *ent.Group
	Member      *ent.GroupMember
	MemberCount int
}

// JoinGroup allows a user to join a group via invitation code.
func (s *Service) JoinGroup(ctx context.Context, code string, userID int) (*JoinGroupResult, error) {
	code = strings.TrimSpace(strings.ToUpper(code))
	if code == "" {
		return nil, ErrInvitationCodeNotFound
	}

	// Find the group by invitation code
	g, err := s.client.Group.Query().
		Where(group.InvitationCode(code)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrInvitationCodeNotFound
		}
		return nil, fmt.Errorf("failed to query group by invitation: %w", err)
	}

	// Check if user exists
	userExists, err := s.client.User.Query().Where(user.ID(userID)).Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check user existence: %w", err)
	}
	if !userExists {
		return nil, ErrUserNotFound
	}

	// Check if user is already a member
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(g.ID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if exists {
		return nil, ErrAlreadyMember
	}

	// Add user as member
	member, err := s.client.GroupMember.Create().
		SetUserID(userID).
		SetGroupID(g.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to add user to group: %w", err)
	}

	// Count members
	memberCount, err := s.client.GroupMember.Query().
		Where(groupmember.GroupID(g.ID)).
		Count(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to count members: %w", err)
	}

	return &JoinGroupResult{
		Group:       g,
		Member:      member,
		MemberCount: memberCount,
	}, nil
}

// UserGroupInfo contains a user's group membership information.
type UserGroupInfo struct {
	Group    *ent.Group
	Role     groupmember.Role
	JoinedAt string
}

// GetUserGroups retrieves all groups that a user belongs to.
func (s *Service) GetUserGroups(ctx context.Context, userID int) ([]*UserGroupInfo, error) {
	// Check if user exists
	userExists, err := s.client.User.Query().Where(user.ID(userID)).Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check user existence: %w", err)
	}
	if !userExists {
		return nil, ErrUserNotFound
	}

	// Query all memberships with group info
	memberships, err := s.client.GroupMember.Query().
		Where(groupmember.UserID(userID)).
		WithGroup().
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to query user groups: %w", err)
	}

	result := make([]*UserGroupInfo, 0, len(memberships))
	for _, m := range memberships {
		result = append(result, &UserGroupInfo{
			Group:    m.Edges.Group,
			Role:     m.Role,
			JoinedAt: m.JoinedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	return result, nil
}

// isGroupAdmin checks if a user is an admin of the specified group.
func (s *Service) isGroupAdmin(ctx context.Context, groupID int, userID int) (bool, error) {
	member, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			// User is not a member of the group
			return false, nil
		}
		return false, fmt.Errorf("failed to check admin status: %w", err)
	}
	return member.Role == groupmember.RoleAdmin, nil
}
