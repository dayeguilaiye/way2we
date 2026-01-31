package points_test

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/membersummary"
	"github.com/way2we/way2we_api/ent/pointlog"
	"github.com/way2we/way2we_api/internal/app/points"

	_ "github.com/mattn/go-sqlite3"
)

func setupPointsService(t *testing.T) (*ent.Client, *points.Service, context.Context, *ent.Group, *ent.User) {
	t.Helper()

	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")

	ctx := context.Background()

	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	groupEntity, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(user.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	service := points.NewService(client)

	return client, service, ctx, groupEntity, user
}

func TestPointsService_AddPoints_Idempotent(t *testing.T) {
	client, service, ctx, groupEntity, user := setupPointsService(t)
	defer client.Close()

	source := points.Source{
		GroupID:    groupEntity.ID,
		SourceType: "agreement",
		SourceID:   "agree-1",
	}

	first, err := service.AddPoints(ctx, groupEntity.ID, user.ID, 10, source)
	require.NoError(t, err)

	second, err := service.AddPoints(ctx, groupEntity.ID, user.ID, 10, source)
	require.NoError(t, err)

	require.Equal(t, first.ID, second.ID)

	logCount, err := client.PointLog.Query().Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 1, logCount)

	summary, err := client.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupEntity.ID),
			membersummary.UserID(user.ID),
		).
		Only(ctx)
	require.NoError(t, err)
	require.Equal(t, 10, summary.Balance)
}

func TestPointsService_DeductPoints_NegativeBalance(t *testing.T) {
	client, service, ctx, groupEntity, user := setupPointsService(t)
	defer client.Close()

	source := points.Source{
		GroupID:    groupEntity.ID,
		SourceType: "redemption",
		SourceID:   "redeem-1",
	}

	logEntry, err := service.DeductPoints(ctx, groupEntity.ID, user.ID, 5, source)
	require.NoError(t, err)
	require.Equal(t, -5, logEntry.Delta)

	summary, err := client.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupEntity.ID),
			membersummary.UserID(user.ID),
		).
		Only(ctx)
	require.NoError(t, err)
	require.Equal(t, -5, summary.Balance)
}

func TestPointsService_RevertPoints(t *testing.T) {
	client, service, ctx, groupEntity, user := setupPointsService(t)
	defer client.Close()

	source := points.Source{
		GroupID:    groupEntity.ID,
		SourceType: "agreement",
		SourceID:   "agree-2",
	}

	_, err := service.AddPoints(ctx, groupEntity.ID, user.ID, 10, source)
	require.NoError(t, err)

	reverted, err := service.RevertPoints(ctx, source)
	require.NoError(t, err)
	require.Equal(t, -10, reverted.Delta)
	require.Equal(t, points.SourceTypeRevert, reverted.SourceType)
	require.Equal(t, "agreement:agree-2", reverted.SourceID)

	summary, err := client.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupEntity.ID),
			membersummary.UserID(user.ID),
		).
		Only(ctx)
	require.NoError(t, err)
	require.Equal(t, 0, summary.Balance)
}

func TestPointsService_ConcurrentUpdates(t *testing.T) {
	client, service, ctx, groupEntity, user := setupPointsService(t)
	defer client.Close()

	const workers = 3
	var wg sync.WaitGroup
	wg.Add(workers)
	errCh := make(chan error, workers)

	for i := 0; i < workers; i++ {
		i := i
		go func() {
			defer wg.Done()
			source := points.Source{
				GroupID:    groupEntity.ID,
				SourceType: "special",
				SourceID:   fmt.Sprintf("s-%d", i),
			}
			var err error
			for attempt := 0; attempt < 5; attempt++ {
				_, err = service.AddPoints(ctx, groupEntity.ID, user.ID, 1, source)
				if err == nil {
					break
				}
				if !strings.Contains(err.Error(), "locked") {
					break
				}
				time.Sleep(100 * time.Millisecond)
			}
			if err != nil {
				errCh <- err
			}
		}()
	}

	wg.Wait()
	close(errCh)
	for err := range errCh {
		require.NoError(t, err)
	}

	logCount, err := client.PointLog.Query().
		Where(pointlog.GroupID(groupEntity.ID), pointlog.UserID(user.ID)).
		Count(ctx)
	require.NoError(t, err)
	require.Equal(t, workers, logCount)

	summary, err := client.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupEntity.ID),
			membersummary.UserID(user.ID),
		).
		Only(ctx)
	require.NoError(t, err)
	require.Equal(t, workers, summary.Balance)
}

func TestPointsService_AddPoints_RollbackOnDuplicate(t *testing.T) {
	client, service, ctx, groupEntity, user := setupPointsService(t)
	defer client.Close()

	source := points.Source{
		GroupID:    groupEntity.ID,
		SourceType: "agreement",
		SourceID:   "agree-rollback",
	}

	first, err := service.AddPoints(ctx, groupEntity.ID, user.ID, 10, source)
	require.NoError(t, err)

	second, err := service.AddPoints(ctx, groupEntity.ID, user.ID, 5, source)
	require.NoError(t, err)
	require.Equal(t, first.ID, second.ID)
	require.Equal(t, 10, second.Delta)

	summary, err := client.MemberSummary.Query().
		Where(
			membersummary.GroupID(groupEntity.ID),
			membersummary.UserID(user.ID),
		).
		Only(ctx)
	require.NoError(t, err)
	require.Equal(t, 10, summary.Balance)
}

func TestPointsService_ListLogs_TimeRangeAndPagination(t *testing.T) {
	client, service, ctx, groupEntity, user := setupPointsService(t)
	defer client.Close()

	t1 := time.Date(2026, 1, 1, 10, 0, 0, 0, time.UTC)
	t2 := t1.Add(1 * time.Hour)
	t3 := t2.Add(1 * time.Hour)

	_, err := client.PointLog.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(user.ID).
		SetDelta(1).
		SetBalanceAfter(1).
		SetSourceType("agreement").
		SetSourceID("a1").
		SetCreatedAt(t1).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.PointLog.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(user.ID).
		SetDelta(1).
		SetBalanceAfter(2).
		SetSourceType("agreement").
		SetSourceID("a2").
		SetCreatedAt(t2).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.PointLog.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(user.ID).
		SetDelta(1).
		SetBalanceAfter(3).
		SetSourceType("agreement").
		SetSourceID("a3").
		SetCreatedAt(t3).
		Save(ctx)
	require.NoError(t, err)

	from := t2
	to := t3

	logs, err := service.ListLogs(ctx, groupEntity.ID, user.ID, user.ID, 1, 0, &from, &to)
	require.NoError(t, err)
	require.Len(t, logs, 1)
	require.True(t, logs[0].CreatedAt.Equal(t3))

	logs, err = service.ListLogs(ctx, groupEntity.ID, user.ID, user.ID, 1, 1, &from, &to)
	require.NoError(t, err)
	require.Len(t, logs, 1)
	require.True(t, logs[0].CreatedAt.Equal(t2))
}
