package redemption

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/redemptionorder"
	"github.com/way2we/way2we_api/ent/reward"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/app/points"
)

// Predefined errors for structured error handling
var (
	ErrNotGroupMember           = errors.New("user is not a member of this group")
	ErrRewardNotFound           = errors.New("reward not found")
	ErrRewardNotInGroup         = errors.New("reward does not belong to this group")
	ErrRewardInactive           = errors.New("reward is not active")
	ErrInvalidQuantity          = errors.New("quantity must be at least 1")
	ErrInsufficientPoints       = errors.New("insufficient points")
	ErrOrderNotFound            = errors.New("order not found")
	ErrOrderNotInGroup          = errors.New("order does not belong to this group")
	ErrOrderNotAwaitingFulfill  = errors.New("order is not awaiting fulfillment")
	ErrOrderNotAwaitingConfirm  = errors.New("order is not awaiting confirmation")
	ErrNotOrderProvider         = errors.New("user is not the order provider")
	ErrNotOrderConsumer         = errors.New("user is not the order consumer")
	ErrNotOrderParticipant      = errors.New("user is not related to the order")
	ErrInvalidRoleFilter        = errors.New("invalid role filter")
	ErrInvalidStatusFilter      = errors.New("invalid status filter")
	ErrUnsatisfiedReasonTooLong = errors.New("unsatisfied reason too long")
)

const (
	pointsSourceTypeCost      = "redemption_cost"
	pointsSourceTypeIncentive = "redemption_incentive"
)

// Service handles redemption order business logic.
type Service struct {
	client        *ent.Client
	groupService  *group.Service
	pointsService *points.Service
}

// NewService creates a new redemption service.
func NewService(client *ent.Client, groupService *group.Service, pointsService *points.Service) *Service {
	return &Service{
		client:        client,
		groupService:  groupService,
		pointsService: pointsService,
	}
}

// CreateOrder creates a redemption order and deducts points atomically.
func (s *Service) CreateOrder(ctx context.Context, groupID int, rewardID int, consumerID int, quantity int) (*ent.RedemptionOrder, error) {
	if quantity < 1 {
		return nil, ErrInvalidQuantity
	}

	if err := s.ensureMember(ctx, groupID, consumerID); err != nil {
		return nil, err
	}

	r, err := s.client.Reward.Get(ctx, rewardID)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrRewardNotFound
		}
		return nil, fmt.Errorf("failed to load reward: %w", err)
	}
	if r.GroupID != groupID {
		return nil, ErrRewardNotInGroup
	}
	if r.Status != reward.StatusActive {
		return nil, ErrRewardInactive
	}

	totalCost := r.CostPoints * quantity

	g, err := s.groupService.GetGroup(ctx, groupID)
	if err != nil {
		return nil, fmt.Errorf("failed to load group settings: %w", err)
	}

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

	now := time.Now()
	status := redemptionorder.StatusAwaitingFulfill
	autoFulfill := r.AutoFulfill
	autoComplete := r.AutoComplete

	builder := tx.RedemptionOrder.Create().
		SetGroupID(groupID).
		SetRewardID(rewardID).
		SetConsumerID(consumerID).
		SetProviderID(r.ProviderID).
		SetQuantity(quantity).
		SetUnitCostPoints(r.CostPoints).
		SetTotalCostPoints(totalCost).
		SetStatus(status).
		SetAutoFulfill(autoFulfill).
		SetAutoComplete(autoComplete).
		SetProviderIncentiveRatio(g.ProviderIncentiveRatio)

	if autoFulfill {
		status = redemptionorder.StatusAwaitingConfirm
		builder = builder.SetStatus(status).SetFulfilledAt(now)
	}
	autoCompleteNow := autoFulfill && autoComplete
	if autoCompleteNow {
		status = redemptionorder.StatusCompleted
		builder = builder.SetStatus(status).SetConfirmedAt(now)
	}

	order, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to create order: %w", err)
	}

	costSource := points.Source{
		GroupID:    groupID,
		SourceType: pointsSourceTypeCost,
		SourceID:   strconv.Itoa(order.ID),
		Reason:     fmt.Sprintf("兑换订单扣分：%d", order.ID),
	}
	_, err = s.pointsService.DeductPointsWithCheckTx(ctx, tx, groupID, consumerID, totalCost, costSource)
	if err != nil {
		if errors.Is(err, points.ErrInsufficientBalance) {
			return nil, ErrInsufficientPoints
		}
		return nil, fmt.Errorf("failed to deduct points: %w", err)
	}

	if autoCompleteNow {
		if err := s.applyIncentiveTx(ctx, tx, order); err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return order, nil
}

// MarkFulfilled marks an order as fulfilled by the provider.
func (s *Service) MarkFulfilled(ctx context.Context, groupID int, orderID int, providerID int) error {
	if err := s.ensureMember(ctx, groupID, providerID); err != nil {
		return err
	}

	order, err := s.client.RedemptionOrder.Get(ctx, orderID)
	if err != nil {
		if ent.IsNotFound(err) {
			return ErrOrderNotFound
		}
		return fmt.Errorf("failed to load order: %w", err)
	}
	if order.GroupID != groupID {
		return ErrOrderNotInGroup
	}
	if order.ProviderID != providerID {
		return ErrNotOrderProvider
	}
	if order.Status != redemptionorder.StatusAwaitingFulfill {
		return ErrOrderNotAwaitingFulfill
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

	now := time.Now()
	nextStatus := redemptionorder.StatusAwaitingConfirm
	update := tx.RedemptionOrder.Update().
		Where(
			redemptionorder.ID(orderID),
			redemptionorder.StatusEQ(redemptionorder.StatusAwaitingFulfill),
		).
		SetStatus(nextStatus).
		SetFulfilledAt(now)

	if order.AutoComplete {
		nextStatus = redemptionorder.StatusCompleted
		update = update.SetStatus(nextStatus).SetConfirmedAt(now)
	}

	updated, err := update.Save(ctx)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}
	if updated == 0 {
		return ErrOrderNotAwaitingFulfill
	}

	if order.AutoComplete {
		if err := s.applyIncentiveTx(ctx, tx, order); err != nil {
			return err
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return nil
}

// ConfirmSatisfied confirms an order as satisfied by the consumer.
func (s *Service) ConfirmSatisfied(ctx context.Context, groupID int, orderID int, consumerID int) error {
	if err := s.ensureMember(ctx, groupID, consumerID); err != nil {
		return err
	}

	order, err := s.client.RedemptionOrder.Get(ctx, orderID)
	if err != nil {
		if ent.IsNotFound(err) {
			return ErrOrderNotFound
		}
		return fmt.Errorf("failed to load order: %w", err)
	}
	if order.GroupID != groupID {
		return ErrOrderNotInGroup
	}
	if order.ConsumerID != consumerID {
		return ErrNotOrderConsumer
	}
	if order.Status != redemptionorder.StatusAwaitingConfirm {
		return ErrOrderNotAwaitingConfirm
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

	now := time.Now()
	updated, err := tx.RedemptionOrder.Update().
		Where(
			redemptionorder.ID(orderID),
			redemptionorder.StatusEQ(redemptionorder.StatusAwaitingConfirm),
		).
		SetStatus(redemptionorder.StatusCompleted).
		SetConfirmedAt(now).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}
	if updated == 0 {
		return ErrOrderNotAwaitingConfirm
	}

	if err := s.applyIncentiveTx(ctx, tx, order); err != nil {
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}
	committed = true

	return nil
}

// MarkUnsatisfied marks an order as unsatisfied by the consumer.
func (s *Service) MarkUnsatisfied(ctx context.Context, groupID int, orderID int, consumerID int, reason string) error {
	if err := s.ensureMember(ctx, groupID, consumerID); err != nil {
		return err
	}
	if len(reason) > 200 {
		return ErrUnsatisfiedReasonTooLong
	}

	order, err := s.client.RedemptionOrder.Get(ctx, orderID)
	if err != nil {
		if ent.IsNotFound(err) {
			return ErrOrderNotFound
		}
		return fmt.Errorf("failed to load order: %w", err)
	}
	if order.GroupID != groupID {
		return ErrOrderNotInGroup
	}
	if order.ConsumerID != consumerID {
		return ErrNotOrderConsumer
	}
	if order.Status != redemptionorder.StatusAwaitingConfirm {
		return ErrOrderNotAwaitingConfirm
	}

	now := time.Now()
	update := s.client.RedemptionOrder.Update().
		Where(
			redemptionorder.ID(orderID),
			redemptionorder.StatusEQ(redemptionorder.StatusAwaitingConfirm),
		).
		SetStatus(redemptionorder.StatusUnsatisfied).
		SetEndedAt(now)
	if reason != "" {
		update = update.SetUnsatisfiedReason(reason)
	}

	updated, err := update.Save(ctx)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}
	if updated == 0 {
		return ErrOrderNotAwaitingConfirm
	}

	return nil
}

// ListMyOrders lists orders for the requester.
func (s *Service) ListMyOrders(ctx context.Context, groupID int, requesterID int, roleFilter string, statusFilter string, limit int, offset int) ([]*ent.RedemptionOrder, error) {
	if err := s.ensureMember(ctx, groupID, requesterID); err != nil {
		return nil, err
	}

	query := s.client.RedemptionOrder.Query().Where(
		redemptionorder.GroupID(groupID),
	).Order(ent.Desc(redemptionorder.FieldCreatedAt)).
		WithReward().
		WithConsumer().
		WithProvider()

	switch roleFilter {
	case "":
		query = query.Where(
			redemptionorder.Or(
				redemptionorder.ConsumerID(requesterID),
				redemptionorder.ProviderID(requesterID),
			),
		)
	case "consumer":
		query = query.Where(redemptionorder.ConsumerID(requesterID))
	case "provider":
		query = query.Where(redemptionorder.ProviderID(requesterID))
	default:
		return nil, ErrInvalidRoleFilter
	}

	if statusFilter != "" {
		switch statusFilter {
		case string(redemptionorder.StatusAwaitingFulfill):
			query = query.Where(redemptionorder.StatusEQ(redemptionorder.StatusAwaitingFulfill))
		case string(redemptionorder.StatusAwaitingConfirm):
			query = query.Where(redemptionorder.StatusEQ(redemptionorder.StatusAwaitingConfirm))
		case string(redemptionorder.StatusCompleted):
			query = query.Where(redemptionorder.StatusEQ(redemptionorder.StatusCompleted))
		case string(redemptionorder.StatusUnsatisfied):
			query = query.Where(redemptionorder.StatusEQ(redemptionorder.StatusUnsatisfied))
		default:
			return nil, ErrInvalidStatusFilter
		}
	}

	if offset > 0 {
		query = query.Offset(offset)
	}
	if limit > 0 {
		query = query.Limit(limit)
	}

	orders, err := query.All(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to query orders: %w", err)
	}
	return orders, nil
}

// GetOrder retrieves a single order by ID.
func (s *Service) GetOrder(ctx context.Context, groupID int, orderID int, requesterID int) (*ent.RedemptionOrder, error) {
	if err := s.ensureMember(ctx, groupID, requesterID); err != nil {
		return nil, err
	}

	order, err := s.client.RedemptionOrder.Query().
		Where(redemptionorder.ID(orderID)).
		WithReward().
		WithConsumer().
		WithProvider().
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, ErrOrderNotFound
		}
		return nil, fmt.Errorf("failed to load order: %w", err)
	}
	if order.GroupID != groupID {
		return nil, ErrOrderNotInGroup
	}

	if order.ConsumerID != requesterID && order.ProviderID != requesterID {
		isAdmin, err := s.groupService.IsGroupAdmin(ctx, groupID, requesterID)
		if err != nil {
			return nil, fmt.Errorf("failed to check admin status: %w", err)
		}
		if !isAdmin {
			return nil, ErrNotOrderParticipant
		}
	}

	return order, nil
}

func (s *Service) ensureMember(ctx context.Context, groupID int, userID int) error {
	exists, err := s.client.GroupMember.Query().
		Where(
			groupmember.GroupID(groupID),
			groupmember.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return fmt.Errorf("failed to check membership: %w", err)
	}
	if !exists {
		return ErrNotGroupMember
	}
	return nil
}

func (s *Service) applyIncentiveTx(ctx context.Context, tx *ent.Tx, order *ent.RedemptionOrder) error {
	if order.ProviderIncentiveRatio <= 0 {
		return nil
	}
	incentive := (order.TotalCostPoints * order.ProviderIncentiveRatio) / 100
	if incentive <= 0 {
		return nil
	}

	source := points.Source{
		GroupID:    order.GroupID,
		SourceType: pointsSourceTypeIncentive,
		SourceID:   strconv.Itoa(order.ID),
		Reason:     fmt.Sprintf("兑换订单激励：%d", order.ID),
	}
	_, err := s.pointsService.ApplyPointsTx(ctx, tx, order.GroupID, order.ProviderID, incentive, source)
	if err != nil {
		return fmt.Errorf("failed to apply incentive: %w", err)
	}
	return nil
}
