package points

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/membersummary"
	"github.com/way2we/way2we_api/ent/pointlog"
)

// Predefined errors for structured error handling
var (
	ErrNotGroupMember      = errors.New("user is not a member of this group")
	ErrInvalidDelta        = errors.New("delta must be non-zero")
	ErrInvalidSource       = errors.New("invalid source")
	ErrSourceGroupMismatch = errors.New("source group mismatch")
	ErrPointLogNotFound    = errors.New("point log not found")
	ErrTargetNotMember     = errors.New("target user is not a member of this group")
)

const (
	SourceTypeRevert = "revert"
)

const maxSourceIDLen = 64

// Source defines the idempotency and tracing info for a points change.
type Source struct {
	GroupID    int
	SourceType string
	SourceID   string
	Reason     string
}

// Service handles points-related business logic.
type Service struct {
	client *ent.Client
}

// NewService creates a new points service.
func NewService(client *ent.Client) *Service {
	return &Service{
		client: client,
	}
}

// AddPoints adds positive points for a member.
func (s *Service) AddPoints(ctx context.Context, groupID int, userID int, delta int, source Source) (*ent.PointLog, error) {
	if delta <= 0 {
		return nil, ErrInvalidDelta
	}
	return s.applyPoints(ctx, groupID, userID, delta, source)
}

// DeductPoints deducts points from a member (delta must be positive).
func (s *Service) DeductPoints(ctx context.Context, groupID int, userID int, delta int, source Source) (*ent.PointLog, error) {
	if delta <= 0 {
		return nil, ErrInvalidDelta
	}
	return s.applyPoints(ctx, groupID, userID, -delta, source)
}

// RevertPoints reverses a prior points change based on the original source.
func (s *Service) RevertPoints(ctx context.Context, source Source) (*ent.PointLog, error) {
	if source.GroupID == 0 || source.SourceType == "" || source.SourceID == "" {
		return nil, ErrInvalidSource
	}

	normalizedID, _ := normalizeSourceID(source.SourceID)
	query := s.client.PointLog.Query().
		Where(
			pointlog.GroupID(source.GroupID),
			pointlog.SourceType(source.SourceType),
		)
	if normalizedID == source.SourceID {
		query = query.Where(pointlog.SourceID(source.SourceID))
	} else {
		query = query.Where(pointlog.Or(
			pointlog.SourceID(normalizedID),
			pointlog.SourceRef(source.SourceID),
		))
	}

	original, err := query.Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrPointLogNotFound
		}
		return nil, fmt.Errorf("failed to load original point log: %w", err)
	}

	revertSource := Source{
		GroupID:    original.GroupID,
		SourceType: SourceTypeRevert,
		SourceID:   fmt.Sprintf("%s:%s", source.SourceType, source.SourceID),
		Reason:     source.Reason,
	}

	return s.applyPoints(ctx, original.GroupID, original.UserID, -original.Delta, revertSource)
}

// GetBalance returns the current balance for a member.
func (s *Service) GetBalance(ctx context.Context, groupID int, userID int) (int, error) {
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return 0, ErrNotGroupMember
	}

	summary, err := s.client.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupID),
			membersummary.UserID(userID),
		).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return 0, nil
		}
		return 0, fmt.Errorf("failed to query member summary: %w", err)
	}

	return summary.Balance, nil
}

func (s *Service) ListLogs(ctx context.Context, groupID int, requesterID int, targetUserID int, limit int, offset int, from *time.Time, to *time.Time) ([]*ent.PointLog, error) {
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

	if targetUserID != requesterID {
		targetExists, err := s.client.GroupMember.Query().
			Where(
				groupmember.GroupID(groupID),
				groupmember.UserID(targetUserID),
			).
			Exist(ctx)
		if err != nil {
			return nil, fmt.Errorf("failed to check target membership: %w", err)
		}
		if !targetExists {
			return nil, ErrTargetNotMember
		}
	}

	query := s.client.PointLog.Query().
		Where(
			pointlog.GroupID(groupID),
			pointlog.UserID(targetUserID),
		).
		Order(ent.Desc(pointlog.FieldCreatedAt))

	if from != nil {
		query = query.Where(pointlog.CreatedAtGTE(*from))
	}
	if to != nil {
		query = query.Where(pointlog.CreatedAtLTE(*to))
	}
	if offset > 0 {
		query = query.Offset(offset)
	}
	if limit > 0 {
		query = query.Limit(limit)
	}

	logs, err := query.All(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to query point logs: %w", err)
	}

	return logs, nil
}

func (s *Service) applyPoints(ctx context.Context, groupID int, userID int, delta int, source Source) (*ent.PointLog, error) {
	if delta == 0 {
		return nil, ErrInvalidDelta
	}
	if source.SourceType == "" || source.SourceID == "" {
		return nil, ErrInvalidSource
	}
	if source.GroupID != 0 && source.GroupID != groupID {
		return nil, ErrSourceGroupMismatch
	}

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

	normalizedID, sourceRef := normalizeSourceID(source.SourceID)

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

	summary, err := tx.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupID),
			membersummary.UserID(userID),
		).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			summary, err = tx.MemberSummary.Create().
				SetGroupID(groupID).
				SetUserID(userID).
				SetBalance(0).
				Save(ctx)
			if err != nil {
				if ent.IsConstraintError(err) {
					summary, err = tx.MemberSummary.Query().
						Where(
							membersummary.GroupID(groupID),
							membersummary.UserID(userID),
						).
						Only(ctx)
				}
				if err != nil {
					return nil, fmt.Errorf("failed to create member summary: %w", err)
				}
			}
		} else {
			return nil, fmt.Errorf("failed to query member summary: %w", err)
		}
	}

	updatedSummary, err := tx.MemberSummary.UpdateOneID(summary.ID).
		AddBalance(delta).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to update member summary: %w", err)
	}

	builder := tx.PointLog.Create().
		SetGroupID(groupID).
		SetUserID(userID).
		SetDelta(delta).
		SetBalanceAfter(updatedSummary.Balance).
		SetSourceType(source.SourceType).
		SetSourceID(normalizedID)
	if source.Reason != "" {
		builder = builder.SetReason(source.Reason)
	}
	if sourceRef != "" {
		builder = builder.SetSourceRef(sourceRef)
	}

	logEntry, err := builder.Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			_ = tx.Rollback()
			committed = true
			existing, lookupErr := s.client.PointLog.Query().
				Where(
					pointlog.GroupID(groupID),
					pointlog.SourceType(source.SourceType),
					pointlog.SourceID(normalizedID),
				).
				Only(ctx)
			if lookupErr != nil {
				return nil, fmt.Errorf("failed to load existing point log: %w", lookupErr)
			}
			return existing, nil
		}
		return nil, fmt.Errorf("failed to create point log: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return logEntry, nil
}

func normalizeSourceID(sourceID string) (string, string) {
	if len(sourceID) <= maxSourceIDLen {
		return sourceID, ""
	}
	sum := sha256.Sum256([]byte(sourceID))
	return hex.EncodeToString(sum[:]), sourceID
}
