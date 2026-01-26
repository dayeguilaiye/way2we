package agreement

import (
	"context"
	"errors"
	"fmt"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/agreement"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/group"
)

// Predefined errors for structured error handling
var (
	ErrAgreementNotFound       = errors.New("agreement not found")
	ErrAgreementNameEmpty      = errors.New("agreement name cannot be empty")
	ErrAgreementNameTooLong    = errors.New("agreement name cannot exceed 50 characters")
	ErrDescriptionTooLong      = errors.New("description cannot exceed 200 characters")
	ErrInvalidPoints           = errors.New("points must be between 1 and 99999")
	ErrPermissionDenied        = errors.New("permission denied")
	ErrNotGroupMember          = errors.New("user is not a member of this group")
	ErrCreateAgreementFailed   = errors.New("failed to create agreement")
	ErrUpdateAgreementFailed   = errors.New("failed to update agreement")
	ErrInvalidStatus           = errors.New("invalid status, must be 'active' or 'inactive'")
	ErrAgreementNotInGroup     = errors.New("agreement does not belong to this group")
)

// Service handles agreement-related business logic.
type Service struct {
	client       *ent.Client
	groupService *group.Service
}

// NewService creates a new agreement service.
func NewService(client *ent.Client, groupService *group.Service) *Service {
	return &Service{
		client:       client,
		groupService: groupService,
	}
}

// CreateInput contains the input for creating an agreement.
type CreateInput struct {
	Name                string `json:"name"`
	Description         string `json:"description"`
	Points              int    `json:"points"`
	RequireConfirmation *bool  `json:"require_confirmation"`
	CoverImageURL       string `json:"cover_image_url"`
	ApplicableMemberIDs []int  `json:"applicable_member_ids"`
}

// UpdateInput contains the input for updating an agreement.
type UpdateInput struct {
	Name                *string `json:"name"`
	Description         *string `json:"description"`
	Points              *int    `json:"points"`
	RequireConfirmation *bool   `json:"require_confirmation"`
	CoverImageURL       *string `json:"cover_image_url"`
	ApplicableMemberIDs *[]int  `json:"applicable_member_ids"`
}

// ListAgreements retrieves all agreements for a group.
// Any group member can view agreements.
func (s *Service) ListAgreements(ctx context.Context, groupID int, userID int, statusFilter string) ([]*ent.Agreement, error) {
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
	query := s.client.Agreement.Query().
		Where(agreement.GroupID(groupID)).
		Order(ent.Desc(agreement.FieldCreatedAt))

	// 3. Apply status filter if provided
	if statusFilter != "" {
		switch statusFilter {
		case "active":
			query = query.Where(agreement.StatusEQ(agreement.StatusActive))
		case "inactive":
			query = query.Where(agreement.StatusEQ(agreement.StatusInactive))
		default:
			return nil, ErrInvalidStatus
		}
	}

	// 4. Execute query
	agreements, err := query.All(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to query agreements: %w", err)
	}

	return agreements, nil
}

// CreateAgreement creates a new agreement in the group.
// Requires create_agreement permission.
func (s *Service) CreateAgreement(ctx context.Context, groupID int, userID int, input CreateInput) (*ent.Agreement, error) {
	// 1. Permission check
	hasPermission, err := s.groupService.HasPermission(ctx, groupID, userID, group.PermissionCreateAgreement)
	if err != nil {
		return nil, fmt.Errorf("failed to check permission: %w", err)
	}
	if !hasPermission {
		return nil, ErrPermissionDenied
	}

	// 2. Validate input
	if input.Name == "" {
		return nil, ErrAgreementNameEmpty
	}
	if len(input.Name) > 50 {
		return nil, ErrAgreementNameTooLong
	}
	if len(input.Description) > 200 {
		return nil, ErrDescriptionTooLong
	}
	if input.Points < 1 || input.Points > 99999 {
		return nil, ErrInvalidPoints
	}

	// 3. Get default require_confirmation from group if not provided
	requireConfirmation := true
	if input.RequireConfirmation != nil {
		requireConfirmation = *input.RequireConfirmation
	} else {
		// Fetch from group settings
		g, err := s.groupService.GetGroup(ctx, groupID)
		if err != nil {
			return nil, fmt.Errorf("failed to get group settings: %w", err)
		}
		requireConfirmation = g.RequireConfirmationDefault
	}

	// 4. Create agreement
	builder := s.client.Agreement.Create().
		SetName(input.Name).
		SetPoints(input.Points).
		SetRequireConfirmation(requireConfirmation).
		SetGroupID(groupID).
		SetCreatorID(userID).
		SetStatus(agreement.StatusActive)

	if input.Description != "" {
		builder = builder.SetDescription(input.Description)
	}

	if input.CoverImageURL != "" {
		builder = builder.SetCoverImageURL(input.CoverImageURL)
	}

	if len(input.ApplicableMemberIDs) > 0 {
		builder = builder.SetApplicableMemberIds(input.ApplicableMemberIDs)
	}

	agr, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrCreateAgreementFailed, err)
	}

	return agr, nil
}

// GetAgreement retrieves a single agreement by ID.
// Any group member can view.
func (s *Service) GetAgreement(ctx context.Context, groupID int, agreementID int, userID int) (*ent.Agreement, error) {
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

	// 2. Get agreement
	agr, err := s.client.Agreement.Get(ctx, agreementID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrAgreementNotFound
		}
		return nil, fmt.Errorf("failed to get agreement: %w", err)
	}

	// 3. Verify agreement belongs to the group
	if agr.GroupID != groupID {
		return nil, ErrAgreementNotInGroup
	}

	return agr, nil
}

// UpdateAgreement updates an existing agreement.
// Requires edit_agreement permission.
func (s *Service) UpdateAgreement(ctx context.Context, groupID int, agreementID int, userID int, input UpdateInput) (*ent.Agreement, error) {
	// 1. Permission check
	hasPermission, err := s.groupService.HasPermission(ctx, groupID, userID, group.PermissionEditAgreement)
	if err != nil {
		return nil, fmt.Errorf("failed to check permission: %w", err)
	}
	if !hasPermission {
		return nil, ErrPermissionDenied
	}

	// 2. Get existing agreement
	agr, err := s.client.Agreement.Get(ctx, agreementID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrAgreementNotFound
		}
		return nil, fmt.Errorf("failed to get agreement: %w", err)
	}

	// 3. Verify agreement belongs to the group
	if agr.GroupID != groupID {
		return nil, ErrAgreementNotInGroup
	}

	// 4. Build update
	builder := s.client.Agreement.UpdateOneID(agreementID)

	if input.Name != nil {
		if *input.Name == "" {
			return nil, ErrAgreementNameEmpty
		}
		if len(*input.Name) > 50 {
			return nil, ErrAgreementNameTooLong
		}
		builder = builder.SetName(*input.Name)
	}

	if input.Description != nil {
		if len(*input.Description) > 200 {
			return nil, ErrDescriptionTooLong
		}
		builder = builder.SetDescription(*input.Description)
	}

	if input.Points != nil {
		if *input.Points < 1 || *input.Points > 99999 {
			return nil, ErrInvalidPoints
		}
		builder = builder.SetPoints(*input.Points)
	}

	if input.RequireConfirmation != nil {
		builder = builder.SetRequireConfirmation(*input.RequireConfirmation)
	}

	if input.CoverImageURL != nil {
		if *input.CoverImageURL == "" {
			builder = builder.ClearCoverImageURL()
		} else {
			builder = builder.SetCoverImageURL(*input.CoverImageURL)
		}
	}

	if input.ApplicableMemberIDs != nil {
		builder = builder.SetApplicableMemberIds(*input.ApplicableMemberIDs)
	}

	// 5. Execute update
	updated, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUpdateAgreementFailed, err)
	}

	return updated, nil
}

// UpdateAgreementStatus updates the status of an agreement (activate/deactivate).
// Requires edit_agreement permission.
func (s *Service) UpdateAgreementStatus(ctx context.Context, groupID int, agreementID int, userID int, status string) (*ent.Agreement, error) {
	// 1. Validate status
	var statusEnum agreement.Status
	switch status {
	case "active":
		statusEnum = agreement.StatusActive
	case "inactive":
		statusEnum = agreement.StatusInactive
	default:
		return nil, ErrInvalidStatus
	}

	// 2. Permission check
	hasPermission, err := s.groupService.HasPermission(ctx, groupID, userID, group.PermissionEditAgreement)
	if err != nil {
		return nil, fmt.Errorf("failed to check permission: %w", err)
	}
	if !hasPermission {
		return nil, ErrPermissionDenied
	}

	// 3. Get existing agreement
	agr, err := s.client.Agreement.Get(ctx, agreementID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrAgreementNotFound
		}
		return nil, fmt.Errorf("failed to get agreement: %w", err)
	}

	// 4. Verify agreement belongs to the group
	if agr.GroupID != groupID {
		return nil, ErrAgreementNotInGroup
	}

	// 5. Update status
	updated, err := s.client.Agreement.UpdateOneID(agreementID).
		SetStatus(statusEnum).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrUpdateAgreementFailed, err)
	}

	return updated, nil
}
