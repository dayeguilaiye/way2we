package reward

import (
	"context"
	"errors"
	"fmt"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/reward"
	"github.com/way2we/way2we_api/internal/app/group"
)

// Predefined errors for structured error handling
var (
	ErrRewardNotFound     = errors.New("reward not found")
	ErrRewardNameEmpty    = errors.New("reward name cannot be empty")
	ErrRewardNameTooLong  = errors.New("reward name cannot exceed 50 characters")
	ErrDescriptionTooLong = errors.New("description cannot exceed 200 characters")
	ErrInvalidCostPoints  = errors.New("cost points must be between 1 and 99999")
	ErrPermissionDenied   = errors.New("permission denied")
	ErrNotGroupMember     = errors.New("user is not a member of this group")
	ErrCreateRewardFailed = errors.New("failed to create reward")
	ErrUpdateRewardFailed = errors.New("failed to update reward")
	ErrInvalidStatus      = errors.New("invalid status, must be 'active' or 'inactive'")
	ErrRewardNotInGroup   = errors.New("reward does not belong to this group")
)

// Service handles reward-related business logic.
type Service struct {
	client       *ent.Client
	groupService *group.Service
}

// NewService creates a new reward service.
func NewService(client *ent.Client, groupService *group.Service) *Service {
	return &Service{
		client:       client,
		groupService: groupService,
	}
}

// CreateInput contains the input for creating a reward.
type CreateInput struct {
	Name          string `json:"name"`
	Description   string `json:"description"`
	CostPoints    int    `json:"cost_points"`
	AutoFulfill   *bool  `json:"auto_fulfill"`
	AutoComplete  *bool  `json:"auto_complete"`
	CoverImageURL string `json:"cover_image_url"`
}

// UpdateInput contains the input for updating a reward.
type UpdateInput struct {
	Name          *string `json:"name"`
	Description   *string `json:"description"`
	CostPoints    *int    `json:"cost_points"`
	AutoFulfill   *bool   `json:"auto_fulfill"`
	AutoComplete  *bool   `json:"auto_complete"`
	CoverImageURL *string `json:"cover_image_url"`
}

// ListRewards retrieves rewards for a group. Default status is active.
// Any group member can view rewards.
func (s *Service) ListRewards(ctx context.Context, groupID int, userID int, statusFilter string) ([]*ent.Reward, error) {
	// 1. Verify user is a member of the group
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return nil, ErrNotGroupMember
	}

	// 2. Build query
	query := s.client.Reward.Query().
		Where(reward.GroupID(groupID)).
		Order(ent.Desc(reward.FieldCreatedAt)).
		WithProvider()

	// 3. Apply status filter (default to active)
	if statusFilter == "" {
		statusFilter = "active"
	}
	switch statusFilter {
	case "active":
		query = query.Where(reward.StatusEQ(reward.StatusActive))
	case "inactive":
		query = query.Where(reward.StatusEQ(reward.StatusInactive))
	default:
		return nil, ErrInvalidStatus
	}

	// 4. Execute query
	rewards, err := query.All(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to query rewards: %w", err)
	}

	return rewards, nil
}

// GetReward retrieves a single reward by ID.
// Any group member can view.
func (s *Service) GetReward(ctx context.Context, groupID int, rewardID int, userID int) (*ent.Reward, error) {
	// 1. Verify user is a member of the group
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return nil, ErrNotGroupMember
	}

	// 2. Get reward
	r, err := s.client.Reward.Query().
		Where(reward.ID(rewardID)).
		WithProvider().
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrRewardNotFound
		}
		return nil, fmt.Errorf("failed to get reward: %w", err)
	}

	// 3. Verify reward belongs to the group
	if r.GroupID != groupID {
		return nil, ErrRewardNotInGroup
	}

	return r, nil
}

// CreateReward creates a new reward in the group.
// Any group member can create (creator becomes provider).
func (s *Service) CreateReward(ctx context.Context, groupID int, userID int, input CreateInput) (*ent.Reward, error) {
	// 1. Verify user is a member of the group
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return nil, ErrNotGroupMember
	}

	// 2. Validate input
	if input.Name == "" {
		return nil, ErrRewardNameEmpty
	}
	if len(input.Name) > 50 {
		return nil, ErrRewardNameTooLong
	}
	if len(input.Description) > 200 {
		return nil, ErrDescriptionTooLong
	}
	if input.CostPoints < 1 || input.CostPoints > 99999 {
		return nil, ErrInvalidCostPoints
	}

	// 3. Defaults from group settings if not provided
	autoFulfill := false
	autoComplete := false
	needsDefaults := input.AutoFulfill == nil || input.AutoComplete == nil
	if needsDefaults {
		g, err := s.groupService.GetGroup(ctx, groupID)
		if err != nil {
			return nil, fmt.Errorf("failed to get group settings: %w", err)
		}
		if input.AutoFulfill == nil {
			autoFulfill = g.AutoFulfillRedemptionDefault
		} else {
			autoFulfill = *input.AutoFulfill
		}
		if input.AutoComplete == nil {
			autoComplete = g.AutoCompleteRedemptionDefault
		} else {
			autoComplete = *input.AutoComplete
		}
	} else {
		autoFulfill = *input.AutoFulfill
		autoComplete = *input.AutoComplete
	}

	// 4. Create reward
	builder := s.client.Reward.Create().
		SetName(input.Name).
		SetCostPoints(input.CostPoints).
		SetAutoFulfill(autoFulfill).
		SetAutoComplete(autoComplete).
		SetGroupID(groupID).
		SetProviderID(userID).
		SetStatus(reward.StatusActive)

	if input.Description != "" {
		builder = builder.SetDescription(input.Description)
	}

	if input.CoverImageURL != "" {
		builder = builder.SetCoverImageURL(input.CoverImageURL)
	}

	r, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrCreateRewardFailed, err)
	}

	return r, nil
}

// UpdateReward updates an existing reward.
// Only provider or group admin can edit.
func (s *Service) UpdateReward(ctx context.Context, groupID int, rewardID int, userID int, input UpdateInput) (*ent.Reward, error) {
	// 1. Verify user is a member of the group
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return nil, ErrNotGroupMember
	}

	// 2. Get existing reward
	r, err := s.client.Reward.Get(ctx, rewardID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrRewardNotFound
		}
		return nil, fmt.Errorf("failed to get reward: %w", err)
	}

	// 3. Verify reward belongs to the group
	if r.GroupID != groupID {
		return nil, ErrRewardNotInGroup
	}

	// 4. Permission check (provider or admin)
	isAdmin, err := s.groupService.IsGroupAdmin(ctx, groupID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check admin status: %w", err)
	}
	if !isAdmin && r.ProviderID != userID {
		return nil, ErrPermissionDenied
	}

	// 5. Build update
	builder := s.client.Reward.UpdateOneID(rewardID)

	if input.Name != nil {
		if *input.Name == "" {
			return nil, ErrRewardNameEmpty
		}
		if len(*input.Name) > 50 {
			return nil, ErrRewardNameTooLong
		}
		builder = builder.SetName(*input.Name)
	}

	if input.Description != nil {
		if len(*input.Description) > 200 {
			return nil, ErrDescriptionTooLong
		}
		builder = builder.SetDescription(*input.Description)
	}

	if input.CostPoints != nil {
		if *input.CostPoints < 1 || *input.CostPoints > 99999 {
			return nil, ErrInvalidCostPoints
		}
		builder = builder.SetCostPoints(*input.CostPoints)
	}

	if input.AutoFulfill != nil {
		builder = builder.SetAutoFulfill(*input.AutoFulfill)
	}

	if input.AutoComplete != nil {
		builder = builder.SetAutoComplete(*input.AutoComplete)
	}

	if input.CoverImageURL != nil {
		if *input.CoverImageURL == "" {
			builder = builder.ClearCoverImageURL()
		} else {
			builder = builder.SetCoverImageURL(*input.CoverImageURL)
		}
	}

	// 6. Execute update
	updated, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUpdateRewardFailed, err)
	}

	return updated, nil
}

// UpdateRewardStatus updates the status of a reward (activate/deactivate).
// Only provider or group admin can update status.
func (s *Service) UpdateRewardStatus(ctx context.Context, groupID int, rewardID int, userID int, status string) (*ent.Reward, error) {
	// 1. Validate status
	var statusEnum reward.Status
	switch status {
	case "active":
		statusEnum = reward.StatusActive
	case "inactive":
		statusEnum = reward.StatusInactive
	default:
		return nil, ErrInvalidStatus
	}

	// 2. Verify user is a member of the group
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return nil, ErrNotGroupMember
	}

	// 3. Get existing reward
	r, err := s.client.Reward.Get(ctx, rewardID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrRewardNotFound
		}
		return nil, fmt.Errorf("failed to get reward: %w", err)
	}

	// 4. Verify reward belongs to the group
	if r.GroupID != groupID {
		return nil, ErrRewardNotInGroup
	}

	// 5. Permission check (provider or admin)
	isAdmin, err := s.groupService.IsGroupAdmin(ctx, groupID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check admin status: %w", err)
	}
	if !isAdmin && r.ProviderID != userID {
		return nil, ErrPermissionDenied
	}

	// 6. Update status
	updated, err := s.client.Reward.UpdateOneID(rewardID).
		SetStatus(statusEnum).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUpdateRewardFailed, err)
	}

	return updated, nil
}
