package reward_test

import (
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/group"
	rewardsvc "github.com/way2we/way2we_api/internal/app/reward"

	_ "github.com/mattn/go-sqlite3"
)

func TestRewardService_CreateReward_DefaultsFromGroup(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	ctx := t.Context()

	user, err := client.User.Create().
		SetNickname("Provider").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	groupEntity, err := client.Group.Create().
		SetName("TestGroup").
		SetAutoFulfillRedemptionDefault(true).
		SetAutoCompleteRedemptionDefault(true).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(user.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	service := rewardsvc.NewService(client, groupService)

	created, err := service.CreateReward(ctx, groupEntity.ID, user.ID, rewardsvc.CreateInput{
		Name:       "Reward",
		CostPoints: 10,
	})
	require.NoError(t, err)
	require.True(t, created.AutoFulfill)
	require.True(t, created.AutoComplete)
	require.Equal(t, user.ID, created.ProviderID)
}

func TestRewardService_UpdateReward_PermissionChecks(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	ctx := t.Context()

	provider, err := client.User.Create().
		SetNickname("Provider").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	member, err := client.User.Create().
		SetNickname("Member").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	admin, err := client.User.Create().
		SetNickname("Admin").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	groupEntity, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(provider.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(member.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(admin.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleAdmin).
		Save(ctx)
	require.NoError(t, err)

	rewardEntity, err := client.Reward.Create().
		SetName("Reward").
		SetCostPoints(20).
		SetGroupID(groupEntity.ID).
		SetProviderID(provider.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	service := rewardsvc.NewService(client, groupService)

	_, err = service.UpdateReward(ctx, groupEntity.ID, rewardEntity.ID, member.ID, rewardsvc.UpdateInput{
		Name: ptrString("Updated"),
	})
	require.ErrorIs(t, err, rewardsvc.ErrPermissionDenied)

	updated, err := service.UpdateReward(ctx, groupEntity.ID, rewardEntity.ID, admin.ID, rewardsvc.UpdateInput{
		Name: ptrString("AdminUpdated"),
	})
	require.NoError(t, err)
	require.Equal(t, "AdminUpdated", updated.Name)
}

func TestRewardService_PinUnpin(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	ctx := t.Context()

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

	rewardEntity, err := client.Reward.Create().
		SetName("Reward").
		SetCostPoints(10).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	service := rewardsvc.NewService(client, groupService)

	err = service.PinReward(ctx, groupEntity.ID, user.ID, rewardEntity.ID)
	require.NoError(t, err)

	refreshedUser, err := client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedIDs, err := refreshedUser.QueryPinnedRewards().IDs(ctx)
	require.NoError(t, err)
	require.Len(t, pinnedIDs, 1)
	require.Equal(t, rewardEntity.ID, pinnedIDs[0])

	err = service.UnpinReward(ctx, groupEntity.ID, user.ID, rewardEntity.ID)
	require.NoError(t, err)

	refreshedUser, err = client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedIDs, err = refreshedUser.QueryPinnedRewards().IDs(ctx)
	require.NoError(t, err)
	require.Empty(t, pinnedIDs)
}

func TestRewardService_ListRewards_PinnedFirst(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	ctx := t.Context()

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

	older := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
	newer := time.Date(2024, 1, 2, 0, 0, 0, 0, time.UTC)

	rewardOlder, err := client.Reward.Create().
		SetName("Older Reward").
		SetCostPoints(10).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		SetCreatedAt(older).
		SetUpdatedAt(older).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.Reward.Create().
		SetName("Newer Reward").
		SetCostPoints(20).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		SetCreatedAt(newer).
		SetUpdatedAt(newer).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	service := rewardsvc.NewService(client, groupService)

	err = service.PinReward(ctx, groupEntity.ID, user.ID, rewardOlder.ID)
	require.NoError(t, err)

	rewards, err := service.ListRewards(ctx, groupEntity.ID, user.ID, "active", false)
	require.NoError(t, err)
	require.Len(t, rewards, 2)
	require.Equal(t, rewardOlder.ID, rewards[0].ID)
	require.NotEmpty(t, rewards[0].Edges.PinnedBy)
}

func TestRewardService_UpdateRewardStatus_PermissionChecks(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	ctx := t.Context()

	provider, err := client.User.Create().
		SetNickname("Provider").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	member, err := client.User.Create().
		SetNickname("Member").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	groupEntity, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(provider.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(member.ID).
		SetGroupID(groupEntity.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	rewardEntity, err := client.Reward.Create().
		SetName("Reward").
		SetCostPoints(20).
		SetGroupID(groupEntity.ID).
		SetProviderID(provider.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	service := rewardsvc.NewService(client, groupService)

	_, err = service.UpdateRewardStatus(ctx, groupEntity.ID, rewardEntity.ID, member.ID, "inactive")
	require.ErrorIs(t, err, rewardsvc.ErrPermissionDenied)

	updated, err := service.UpdateRewardStatus(ctx, groupEntity.ID, rewardEntity.ID, provider.ID, "inactive")
	require.NoError(t, err)
	require.Equal(t, "inactive", string(updated.Status))
}

func ptrString(v string) *string {
	return &v
}
