package group_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/group"

	_ "github.com/mattn/go-sqlite3"
)

func TestService_UpdateMemberRole(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// 1. Setup: Create Admin User, Group
	admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("valid").Save(ctx)
	require.NoError(t, err)

	groupResult, err := service.CreateGroup(ctx, admin.ID, "TestGroup")
	require.NoError(t, err)
	groupID := groupResult.Group.ID

	// 2. Setup: Create Member User, Join Group
	memberUser, err := client.User.Create().SetNickname("Member").SetPasswordHash("valid").Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetUserID(memberUser.ID).
		SetGroupID(groupID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	t.Run("admin can promote member to admin", func(t *testing.T) {
		err := service.UpdateMemberRole(ctx, groupID, memberUser.ID, groupmember.RoleAdmin, admin.ID)
		require.NoError(t, err)

		// verify DB
		m, err := client.GroupMember.Query().
			Where(groupmember.UserID(memberUser.ID), groupmember.GroupID(groupID)).
			Only(ctx)
		require.NoError(t, err)
		assert.Equal(t, groupmember.RoleAdmin, m.Role)
	})

	t.Run("admin cannot demote ONLY admin", func(t *testing.T) {
		// Ensure only one admin exists (revert previous test effect if needed, but sqlite memory is shared per test function)
		// Reset memberUser to Member role to be safe
		_, err := client.GroupMember.Update().
			Where(groupmember.UserID(memberUser.ID), groupmember.GroupID(groupID)).
			SetRole(groupmember.RoleMember).
			Save(ctx)
		require.NoError(t, err)

		// Try to demote the admin (creator)
		err = service.UpdateMemberRole(ctx, groupID, admin.ID, groupmember.RoleMember, admin.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrLastAdminCannotDemote)
	})

	t.Run("member cannot update role", func(t *testing.T) {
		err := service.UpdateMemberRole(ctx, groupID, admin.ID, groupmember.RoleMember, memberUser.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrNotAdmin)
	})
}

func TestService_UpdateMemberPermissions(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Setup
	admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("valid").Save(ctx)
	require.NoError(t, err)
	groupResult, err := service.CreateGroup(ctx, admin.ID, "TestGroup")
	require.NoError(t, err)
	groupID := groupResult.Group.ID

	memberUser, err := client.User.Create().SetNickname("Member").SetPasswordHash("valid").Save(ctx)
	require.NoError(t, err)
	_, err = client.GroupMember.Create().SetUserID(memberUser.ID).SetGroupID(groupID).SetRole(groupmember.RoleMember).Save(ctx)
	require.NoError(t, err)

	t.Run("admin can update permissions", func(t *testing.T) {
		perms := []string{"create_agreement", "edit_agreement"}
		err := service.UpdateMemberPermissions(ctx, groupID, memberUser.ID, perms, admin.ID)
		require.NoError(t, err)

		// verify DB
		m, err := client.GroupMember.Query().
			Where(groupmember.UserID(memberUser.ID), groupmember.GroupID(groupID)).
			Only(ctx)
		require.NoError(t, err)

		// Ent JSON field might come back as []interface{}, depend on scan.
		// But in test check we can cast or use deep equal if typed
		// We rely on service layer to verify save
		// Let's assume we can cast back or just check if non-empty for now if type issues
		// However Ent generated code for JSON []string should be []string
		// But the field definition was field.JSON("permissions", []string{})
		// So generated struct field Permissions should be []string

		// The generated struct might need checking.
		// "Permissions []string `json:"permissions,omitempty"`"
		assert.Equal(t, perms, m.Permissions)
	})

	t.Run("member cannot update permissions", func(t *testing.T) {
		perms := []string{"create_agreement"}
		err := service.UpdateMemberPermissions(ctx, groupID, admin.ID, perms, memberUser.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrNotAdmin)
	})

	t.Run("invalid permission is rejected", func(t *testing.T) {
		err := service.UpdateMemberPermissions(ctx, groupID, memberUser.ID, []string{"super_power"}, admin.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrPermissionInvalid)
	})
}
