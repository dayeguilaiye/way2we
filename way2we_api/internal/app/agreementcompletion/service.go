package agreementcompletion

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/agreement"
	"github.com/way2we/way2we_api/ent/agreementcompletion"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/app/points"
)

// Predefined errors for structured error handling
var (
	ErrNotGroupMember         = errors.New("user is not a member of this group")
	ErrPermissionDenied       = errors.New("permission denied")
	ErrAgreementNotFound      = errors.New("agreement not found")
	ErrAgreementNotInGroup    = errors.New("agreement does not belong to this group")
	ErrAgreementInactive      = errors.New("agreement is not active")
	ErrCompleterNotMember     = errors.New("completer is not a member of this group")
	ErrCompleterNotApplicable = errors.New("completer is not applicable")
	ErrCompletionNotFound     = errors.New("completion not found")
	ErrCompletionNotInGroup   = errors.New("completion does not belong to this group")
	ErrCompletionNotPending   = errors.New("completion is not pending")
	ErrCannotSelfConfirm      = errors.New("completer cannot confirm their own completion")
	ErrRejectReasonTooLong    = errors.New("rejected reason too long")
)

const (
	pointsSourceType = "agreement_completion"
)

// Service handles agreement completion-related business logic.
type Service struct {
	client        *ent.Client
	groupService  *group.Service
	pointsService *points.Service
}

// NewService creates a new agreement completion service.
func NewService(client *ent.Client, groupService *group.Service, pointsService *points.Service) *Service {
	return &Service{
		client:        client,
		groupService:  groupService,
		pointsService: pointsService,
	}
}

// CreateCompletion creates an agreement completion record.
func (s *Service) CreateCompletion(ctx context.Context, groupID int, agreementID int, recorderID int, completerID int) (*ent.AgreementCompletion, error) {
	// default to self
	if completerID == 0 {
		completerID = recorderID
	}

	// 1. Verify recorder is a member
	recorderIsMember, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(recorderID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check recorder membership: %w", err)
	}
	if !recorderIsMember {
		return nil, ErrNotGroupMember
	}

	// 2. If recording for others, verify permission
	if completerID != recorderID {
		hasPermission, err := s.groupService.HasPermission(ctx, groupID, recorderID, group.PermissionRecordForOthers)
		if err != nil {
			return nil, fmt.Errorf("failed to check permission: %w", err)
		}
		if !hasPermission {
			return nil, ErrPermissionDenied
		}
	}

	// 3. Verify completer is a member
	completerIsMember, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(completerID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check completer membership: %w", err)
	}
	if !completerIsMember {
		return nil, ErrCompleterNotMember
	}

	// 4. Load agreement and validate
	agr, err := s.client.Agreement.Get(ctx, agreementID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrAgreementNotFound
		}
		return nil, fmt.Errorf("failed to load agreement: %w", err)
	}
	if agr.GroupID != groupID {
		return nil, ErrAgreementNotInGroup
	}
	if agr.Status != agreement.StatusActive {
		return nil, ErrAgreementInactive
	}
	if len(agr.ApplicableMemberIds) > 0 {
		applicable := false
		for _, id := range agr.ApplicableMemberIds {
			if id == completerID {
				applicable = true
				break
			}
		}
		if !applicable {
			return nil, ErrCompleterNotApplicable
		}
	}

	requireConfirmation := agr.RequireConfirmation
	status := agreementcompletion.StatusPending
	if !requireConfirmation {
		status = agreementcompletion.StatusConfirmed
	}

	now := time.Now()

	tx, err := s.client.Tx(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to start transaction: %w", err)
	}
	committed := false
	defer func() {
		if !committed {
			_ = tx.Rollback()
		}
	}()

	builder := tx.AgreementCompletion.Create().
		SetGroupID(groupID).
		SetAgreementID(agreementID).
		SetCompleterID(completerID).
		SetRecorderID(recorderID).
		SetPoints(agr.Points).
		SetRequireConfirmation(requireConfirmation).
		SetStatus(status)
	if status == agreementcompletion.StatusConfirmed {
		builder = builder.SetConfirmedAt(now).SetConfirmedBy(recorderID)
	}

	completion, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to create completion: %w", err)
	}

	if status == agreementcompletion.StatusConfirmed {
		source := points.Source{
			GroupID:    groupID,
			SourceType: pointsSourceType,
			SourceID:   strconv.Itoa(completion.ID),
			Reason:     fmt.Sprintf("确认约定完成：%d", agreementID),
		}
		_, err = s.pointsService.ApplyPointsTx(ctx, tx, groupID, completerID, agr.Points, source)
		if err != nil {
			return nil, fmt.Errorf("failed to apply points: %w", err)
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return completion, nil
}

// ListPending lists pending completions for a group.
func (s *Service) ListPending(ctx context.Context, groupID int, requesterID int, limit int, offset int) ([]*ent.AgreementCompletion, error) {
	// 1. Verify requester is a member
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(requesterID),
		).
		Exist(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return nil, ErrNotGroupMember
	}

	query := s.client.AgreementCompletion.Query().
		Where(
			agreementcompletion.GroupID(groupID),
			agreementcompletion.StatusEQ(agreementcompletion.StatusPending),
		).
		Order(ent.Desc(agreementcompletion.FieldCreatedAt)).
		WithAgreement().
		WithCompleter().
		WithRecorder()

	if offset > 0 {
		query = query.Offset(offset)
	}
	if limit > 0 {
		query = query.Limit(limit)
	}

	completions, err := query.All(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to query completions: %w", err)
	}

	return completions, nil
}

// Confirm confirms a pending completion and applies points atomically.
func (s *Service) Confirm(ctx context.Context, groupID int, completionID int, confirmerID int) error {
	// 1. Verify confirmer is a member
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(confirmerID),
		).
		Exist(ctx)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return ErrNotGroupMember
	}

	tx, err := s.client.Tx(ctx)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	committed := false
	defer func() {
		if !committed {
			_ = tx.Rollback()
		}
	}()

	completion, err := tx.AgreementCompletion.Get(ctx, completionID)
	if err != nil {
		if ent.IsNotFound(err) {
			return ErrCompletionNotFound
		}
		return fmt.Errorf("failed to load completion: %w", err)
	}
	if completion.GroupID != groupID {
		return ErrCompletionNotInGroup
	}
	if completion.CompleterID == confirmerID {
		return ErrCannotSelfConfirm
	}

	now := time.Now()
	updated, err := tx.AgreementCompletion.Update().
		Where(
			agreementcompletion.ID(completionID),
			agreementcompletion.StatusEQ(agreementcompletion.StatusPending),
		).
		SetStatus(agreementcompletion.StatusConfirmed).
		SetConfirmedBy(confirmerID).
		SetConfirmedAt(now).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("failed to update completion status: %w", err)
	}
	if updated == 0 {
		return ErrCompletionNotPending
	}

	source := points.Source{
		GroupID:    groupID,
		SourceType: pointsSourceType,
		SourceID:   strconv.Itoa(completion.ID),
		Reason:     fmt.Sprintf("确认约定完成：%d", completion.AgreementID),
	}
	_, err = s.pointsService.ApplyPointsTx(ctx, tx, groupID, completion.CompleterID, completion.Points, source)
	if err != nil {
		return fmt.Errorf("failed to apply points: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return nil
}

// Reject rejects a pending completion.
func (s *Service) Reject(ctx context.Context, groupID int, completionID int, rejecterID int, reason string) error {
	if len(reason) > 200 {
		return ErrRejectReasonTooLong
	}

	// 1. Verify rejecter is a member
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(rejecterID),
		).
		Exist(ctx)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return ErrNotGroupMember
	}

	tx, err := s.client.Tx(ctx)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	committed := false
	defer func() {
		if !committed {
			_ = tx.Rollback()
		}
	}()

	completion, err := tx.AgreementCompletion.Get(ctx, completionID)
	if err != nil {
		if ent.IsNotFound(err) {
			return ErrCompletionNotFound
		}
		return fmt.Errorf("failed to load completion: %w", err)
	}
	if completion.GroupID != groupID {
		return ErrCompletionNotInGroup
	}

	now := time.Now()
	update := tx.AgreementCompletion.Update().
		Where(
			agreementcompletion.ID(completionID),
			agreementcompletion.StatusEQ(agreementcompletion.StatusPending),
		).
		SetStatus(agreementcompletion.StatusRejected).
		SetRejectedAt(now)
	if reason != "" {
		update = update.SetRejectedReason(reason)
	}

	updated, err := update.Save(ctx)
	if err != nil {
		return fmt.Errorf("failed to update completion status: %w", err)
	}
	if updated == 0 {
		return ErrCompletionNotPending
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return nil
}
