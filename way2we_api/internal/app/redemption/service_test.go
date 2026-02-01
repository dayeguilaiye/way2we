package redemption_test

import (
	"context"
	"fmt"
	"sync"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/pointlog"
	"github.com/way2we/way2we_api/ent/redemptionorder"
	"github.com/way2we/way2we_api/ent/reward"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/app/points"
	"github.com/way2we/way2we_api/internal/app/redemption"

	_ "github.com/mattn/go-sqlite3"
)

func setupRedemptionService(t *testing.T) (*ent.Client, *redemption.Service, *points.Service, context.Context, *ent.Group, *ent.User, *ent.User, *ent.User) {
	t.Helper()

	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")
	ctx := context.Background()

	groupEntity, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	consumer, err := client.User.Create().
		SetNickname("Consumer").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	provider, err := client.User.Create().
		SetNickname("Provider").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	other, err := client.User.Create().
		SetNickname("Other").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(consumer.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(provider.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(other.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	pointsService := points.NewService(client)
	service := redemption.NewService(client, groupService, pointsService)

	return client, service, pointsService, ctx, groupEntity, consumer, provider, other
}

func createReward(t *testing.T, ctx context.Context, client *ent.Client, groupID int, providerID int, cost int, autoFulfill bool, autoComplete bool) *ent.Reward {
	t.Helper()

	r, err := client.Reward.Create().
		SetName("Reward").
		SetCostPoints(cost).
		SetGroupID(groupID).
		SetProviderID(providerID).
		SetStatus(reward.StatusActive).
		SetAutoFulfill(autoFulfill).
		SetAutoComplete(autoComplete).
		Save(ctx)
	require.NoError(t, err)
	return r
}

func seedPoints(t *testing.T, svc *points.Service, ctx context.Context, groupID int, userID int, delta int) {
	t.Helper()

	_, err := svc.AddPoints(ctx, groupID, userID, delta, points.Source{
		GroupID:    groupID,
		SourceType: "seed",
		SourceID:   fmt.Sprintf("seed-%d-%d", userID, delta),
		Reason:     "seed points",
	})
	require.NoError(t, err)
}

func TestCreateOrder_InsufficientPoints(t *testing.T) {
	client, service, _, ctx, groupEntity, consumer, provider, _ := setupRedemptionService(t)
	defer client.Close()

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 100, false, false)

	_, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 1)
	require.ErrorIs(t, err, redemption.ErrInsufficientPoints)

	count, err := client.RedemptionOrder.Query().Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 0, count)

	logCount, err := client.PointLog.Query().Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 0, logCount)
}

func TestCreateOrder_AutoFulfillAutoComplete(t *testing.T) {
	client, service, pointsService, ctx, groupEntity, consumer, provider, _ := setupRedemptionService(t)
	defer client.Close()

	_, err := client.Group.UpdateOneID(groupEntity.ID).
		SetProviderIncentiveRatio(10).
		Save(ctx)
	require.NoError(t, err)

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 50, true, true)
	seedPoints(t, pointsService, ctx, groupEntity.ID, consumer.ID, 200)

	order, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 2)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusCompleted, order.Status)
	require.NotNil(t, order.FulfilledAt)
	require.NotNil(t, order.ConfirmedAt)

	incentiveCount, err := client.PointLog.Query().
		Where(pointlog.SourceType("redemption_incentive")).
		Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 1, incentiveCount)

	costCount, err := client.PointLog.Query().
		Where(pointlog.SourceType("redemption_cost")).
		Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 1, costCount)

	consumerBalance, err := pointsService.GetBalance(ctx, groupEntity.ID, consumer.ID)
	require.NoError(t, err)
	require.Equal(t, 100, consumerBalance)

	providerBalance, err := pointsService.GetBalance(ctx, groupEntity.ID, provider.ID)
	require.NoError(t, err)
	require.Equal(t, 10, providerBalance)
}

func TestConfirm_ConcurrentNoDuplicateIncentive(t *testing.T) {
	client, service, pointsService, ctx, groupEntity, consumer, provider, _ := setupRedemptionService(t)
	defer client.Close()

	_, err := client.Group.UpdateOneID(groupEntity.ID).
		SetProviderIncentiveRatio(15).
		Save(ctx)
	require.NoError(t, err)

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 99, true, false)
	seedPoints(t, pointsService, ctx, groupEntity.ID, consumer.ID, 200)

	order, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 1)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusAwaitingConfirm, order.Status)

	var wg sync.WaitGroup
	errs := make([]error, 2)

	wg.Add(2)
	go func() {
		defer wg.Done()
		errs[0] = service.ConfirmSatisfied(ctx, groupEntity.ID, order.ID, consumer.ID)
	}()
	go func() {
		defer wg.Done()
		errs[1] = service.ConfirmSatisfied(ctx, groupEntity.ID, order.ID, consumer.ID)
	}()
	wg.Wait()

	successCount := 0
	for _, err := range errs {
		if err == nil {
			successCount++
		}
	}
	require.Equal(t, 1, successCount)

	incentiveLogs, err := client.PointLog.Query().
		Where(pointlog.SourceType("redemption_incentive")).
		All(ctx)
	require.NoError(t, err)
	require.Len(t, incentiveLogs, 1)
	require.Equal(t, 14, incentiveLogs[0].Delta)

	order, err = client.RedemptionOrder.Get(ctx, order.ID)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusCompleted, order.Status)
}

func TestConfirm_NoIncentiveWhenRatioZero(t *testing.T) {
	client, service, pointsService, ctx, groupEntity, consumer, provider, _ := setupRedemptionService(t)
	defer client.Close()

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 50, true, false)
	seedPoints(t, pointsService, ctx, groupEntity.ID, consumer.ID, 200)

	order, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 1)
	require.NoError(t, err)

	err = service.ConfirmSatisfied(ctx, groupEntity.ID, order.ID, consumer.ID)
	require.NoError(t, err)

	incentiveCount, err := client.PointLog.Query().
		Where(pointlog.SourceType("redemption_incentive")).
		Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 0, incentiveCount)
}

func TestPermissionChecks(t *testing.T) {
	client, service, pointsService, ctx, groupEntity, consumer, provider, other := setupRedemptionService(t)
	defer client.Close()

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 20, false, false)
	seedPoints(t, pointsService, ctx, groupEntity.ID, consumer.ID, 100)

	order, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 1)
	require.NoError(t, err)

	err = service.MarkFulfilled(ctx, groupEntity.ID, order.ID, other.ID)
	require.ErrorIs(t, err, redemption.ErrNotOrderProvider)

	err = service.ConfirmSatisfied(ctx, groupEntity.ID, order.ID, other.ID)
	require.ErrorIs(t, err, redemption.ErrNotOrderConsumer)

	err = service.MarkUnsatisfied(ctx, groupEntity.ID, order.ID, other.ID, "nope")
	require.ErrorIs(t, err, redemption.ErrNotOrderConsumer)
}

func TestMarkFulfilled_SetsStatusAndTimestamp(t *testing.T) {
	client, service, pointsService, ctx, groupEntity, consumer, provider, _ := setupRedemptionService(t)
	defer client.Close()

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 30, false, false)
	seedPoints(t, pointsService, ctx, groupEntity.ID, consumer.ID, 100)

	order, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 1)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusAwaitingFulfill, order.Status)

	err = service.MarkFulfilled(ctx, groupEntity.ID, order.ID, provider.ID)
	require.NoError(t, err)

	updated, err := client.RedemptionOrder.Get(ctx, order.ID)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusAwaitingConfirm, updated.Status)
	require.NotNil(t, updated.FulfilledAt)
	require.Nil(t, updated.ConfirmedAt)
}

func TestMarkUnsatisfied_SetsStatusAndEndedAt(t *testing.T) {
	client, service, pointsService, ctx, groupEntity, consumer, provider, _ := setupRedemptionService(t)
	defer client.Close()

	r := createReward(t, ctx, client, groupEntity.ID, provider.ID, 30, true, false)
	seedPoints(t, pointsService, ctx, groupEntity.ID, consumer.ID, 100)

	order, err := service.CreateOrder(ctx, groupEntity.ID, r.ID, consumer.ID, 1)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusAwaitingConfirm, order.Status)

	err = service.MarkUnsatisfied(ctx, groupEntity.ID, order.ID, consumer.ID, "not ok")
	require.NoError(t, err)

	updated, err := client.RedemptionOrder.Get(ctx, order.ID)
	require.NoError(t, err)
	require.Equal(t, redemptionorder.StatusUnsatisfied, updated.Status)
	require.NotNil(t, updated.EndedAt)
	require.Equal(t, "not ok", updated.UnsatisfiedReason)
}
