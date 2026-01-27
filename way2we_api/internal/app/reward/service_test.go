package reward_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/app/reward"

	_ "github.com/mattn/go-sqlite3"
)

func TestService_CreateReward_DefaultsFromGroup(t *testing.T) {
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
	rewardService := reward.NewService(client, groupService)

	created, err := rewardService.CreateReward(ctx, groupEntity.ID, user.ID, reward.CreateInput{
		Name:       "Reward",
		CostPoints: 10,
	})
	require.NoError(t, err)
	assert.True(t, created.AutoFulfill)
	assert.True(t, created.AutoComplete)
	assert.Equal(t, user.ID, created.ProviderID)
}

func TestService_CreateReward_NotMember(t *testing.T) {
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
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	rewardService := reward.NewService(client, groupService)

	_, err = rewardService.CreateReward(ctx, groupEntity.ID, user.ID, reward.CreateInput{
		Name:       "Reward",
		CostPoints: 10,
	})
	assert.ErrorIs(t, err, reward.ErrNotGroupMember)
}

func TestService_UpdateReward_PermissionChecks(t *testing.T) {
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
	rewardService := reward.NewService(client, groupService)

	_, err = rewardService.UpdateReward(ctx, groupEntity.ID, rewardEntity.ID, member.ID, reward.UpdateInput{
		Name: ptrString("Updated"),
	})
	assert.ErrorIs(t, err, reward.ErrPermissionDenied)

	updated, err := rewardService.UpdateReward(ctx, groupEntity.ID, rewardEntity.ID, admin.ID, reward.UpdateInput{
		Name: ptrString("AdminUpdated"),
	})
	require.NoError(t, err)
	assert.Equal(t, "AdminUpdated", updated.Name)
}

func TestService_UpdateRewardStatus_PermissionChecks(t *testing.T) {
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
	rewardService := reward.NewService(client, groupService)

	_, err = rewardService.UpdateRewardStatus(ctx, groupEntity.ID, rewardEntity.ID, member.ID, "inactive")
	assert.ErrorIs(t, err, reward.ErrPermissionDenied)

	updated, err := rewardService.UpdateRewardStatus(ctx, groupEntity.ID, rewardEntity.ID, provider.ID, "inactive")
	require.NoError(t, err)
	assert.Equal(t, "inactive", string(updated.Status))
}

func ptrString(v string) *string {
	return &v
}
