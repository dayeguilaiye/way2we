package group_test

import (
	"context"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/group"

	_ "github.com/mattn/go-sqlite3"
)

func TestService_CreateGroup(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create a user first
	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	t.Run("successful group creation", func(t *testing.T) {
		result, err := service.CreateGroup(ctx, user.ID, "我的家庭")
		require.NoError(t, err)

		// Verify group was created
		assert.NotNil(t, result.Group)
		assert.Equal(t, "我的家庭", result.Group.Name)
		assert.NotZero(t, result.Group.ID)

		// Verify member was created with admin role
		assert.NotNil(t, result.Member)
		assert.Equal(t, user.ID, result.Member.UserID)
		assert.Equal(t, result.Group.ID, result.Member.GroupID)
		assert.Equal(t, groupmember.RoleAdmin, result.Member.Role)

		// Verify group exists in database
		dbGroup, err := client.Group.Get(ctx, result.Group.ID)
		require.NoError(t, err)
		assert.Equal(t, "我的家庭", dbGroup.Name)

		// Verify member exists in database
		dbMember, err := client.GroupMember.Get(ctx, result.Member.ID)
		require.NoError(t, err)
		assert.Equal(t, groupmember.RoleAdmin, dbMember.Role)
	})

	t.Run("empty name validation", func(t *testing.T) {
		_, err := service.CreateGroup(ctx, user.ID, "")
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrGroupNameEmpty)
	})

	t.Run("name too long validation", func(t *testing.T) {
		longName := strings.Repeat("a", 31)
		_, err := service.CreateGroup(ctx, user.ID, longName)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrGroupNameTooLong)
	})

	t.Run("name exactly 30 characters", func(t *testing.T) {
		name30 := strings.Repeat("a", 30)
		result, err := service.CreateGroup(ctx, user.ID, name30)
		require.NoError(t, err)
		assert.Equal(t, name30, result.Group.Name)
	})

	t.Run("name with 1 character", func(t *testing.T) {
		result, err := service.CreateGroup(ctx, user.ID, "A")
		require.NoError(t, err)
		assert.Equal(t, "A", result.Group.Name)
	})

	t.Run("non-existent user ID", func(t *testing.T) {
		// Use a user ID that doesn't exist
		_, err := service.CreateGroup(ctx, 99999, "Test Group")
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrUserNotFound)
	})

	t.Run("name with whitespace is trimmed", func(t *testing.T) {
		result, err := service.CreateGroup(ctx, user.ID, "  My Group  ")
		require.NoError(t, err)
		assert.Equal(t, "My Group", result.Group.Name)
	})

	t.Run("whitespace-only name is rejected", func(t *testing.T) {
		_, err := service.CreateGroup(ctx, user.ID, "   ")
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrGroupNameEmpty)
	})
}

func TestService_GetGroup(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create a group directly
	g, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	t.Run("get existing group", func(t *testing.T) {
		result, err := service.GetGroup(ctx, g.ID)
		require.NoError(t, err)
		assert.Equal(t, g.ID, result.ID)
		assert.Equal(t, "TestGroup", result.Name)
	})

	t.Run("get non-existent group", func(t *testing.T) {
		_, err := service.GetGroup(ctx, 99999)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrGroupNotFound)
	})
}

func TestService_GenerateInvitationCode(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create a group
	g, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	t.Run("generate code for existing group", func(t *testing.T) {
		code, err := service.GenerateInvitationCode(ctx, g.ID)
		require.NoError(t, err)
		assert.Len(t, code, 6)

		// Verify all characters are from the allowed charset
		charset := "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
		for _, c := range code {
			assert.Contains(t, charset, string(c))
		}

		// Verify code was saved to database
		updatedGroup, err := client.Group.Get(ctx, g.ID)
		require.NoError(t, err)
		assert.NotNil(t, updatedGroup.InvitationCode)
		assert.Equal(t, code, *updatedGroup.InvitationCode)
	})

	t.Run("generate code for non-existent group", func(t *testing.T) {
		_, err := service.GenerateInvitationCode(ctx, 99999)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrGroupNotFound)
	})
}

func TestService_GetInvitationCode(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create a user
	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create another user (non-admin)
	user2, err := client.User.Create().
		SetNickname("TestUser2").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create a group with the user as admin
	result, err := service.CreateGroup(ctx, user.ID, "TestGroup")
	require.NoError(t, err)

	t.Run("admin can get invitation code", func(t *testing.T) {
		code, err := service.GetInvitationCode(ctx, result.Group.ID, user.ID)
		require.NoError(t, err)
		assert.Len(t, code, 6)
	})

	t.Run("non-admin cannot get invitation code", func(t *testing.T) {
		_, err := service.GetInvitationCode(ctx, result.Group.ID, user2.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrNotAdmin)
	})

	t.Run("non-member cannot get invitation code", func(t *testing.T) {
		_, err := service.GetInvitationCode(ctx, result.Group.ID, 99999)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrNotAdmin)
	})

	t.Run("returns existing code if already generated", func(t *testing.T) {
		code1, err := service.GetInvitationCode(ctx, result.Group.ID, user.ID)
		require.NoError(t, err)

		code2, err := service.GetInvitationCode(ctx, result.Group.ID, user.ID)
		require.NoError(t, err)

		assert.Equal(t, code1, code2)
	})
}

func TestService_RefreshInvitationCode(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create a user
	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create another user (non-admin)
	user2, err := client.User.Create().
		SetNickname("TestUser2").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create a group with the user as admin
	result, err := service.CreateGroup(ctx, user.ID, "TestGroup")
	require.NoError(t, err)

	// Get initial code
	oldCode, err := service.GetInvitationCode(ctx, result.Group.ID, user.ID)
	require.NoError(t, err)

	t.Run("admin can refresh invitation code", func(t *testing.T) {
		newCode, err := service.RefreshInvitationCode(ctx, result.Group.ID, user.ID)
		require.NoError(t, err)
		assert.Len(t, newCode, 6)
		// New code should be different (very high probability)
		// Note: There's a tiny chance they could be the same, but extremely unlikely
	})

	t.Run("non-admin cannot refresh invitation code", func(t *testing.T) {
		_, err := service.RefreshInvitationCode(ctx, result.Group.ID, user2.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrNotAdmin)
	})

	t.Run("old code is invalidated after refresh", func(t *testing.T) {
		newCode, err := service.RefreshInvitationCode(ctx, result.Group.ID, user.ID)
		require.NoError(t, err)

		// Verify the old code no longer works
		_, err = service.GetGroupByInvitation(ctx, oldCode)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrInvitationCodeNotFound)

		// But new code works
		preview, err := service.GetGroupByInvitation(ctx, newCode)
		require.NoError(t, err)
		assert.Equal(t, result.Group.ID, preview.ID)
	})
}

func TestService_GetGroupByInvitation(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create a user
	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create a group with the user as admin
	result, err := service.CreateGroup(ctx, user.ID, "MyFamily")
	require.NoError(t, err)

	// Generate invitation code
	code, err := service.GenerateInvitationCode(ctx, result.Group.ID)
	require.NoError(t, err)

	t.Run("get group by valid invitation code", func(t *testing.T) {
		preview, err := service.GetGroupByInvitation(ctx, code)
		require.NoError(t, err)
		assert.Equal(t, result.Group.ID, preview.ID)
		assert.Equal(t, "MyFamily", preview.Name)
		assert.Equal(t, 1, preview.MemberCount) // Just the admin
	})

	t.Run("case insensitive code lookup", func(t *testing.T) {
		preview, err := service.GetGroupByInvitation(ctx, strings.ToLower(code))
		require.NoError(t, err)
		assert.Equal(t, result.Group.ID, preview.ID)
	})

	t.Run("invalid invitation code", func(t *testing.T) {
		_, err := service.GetGroupByInvitation(ctx, "XXXXXX")
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrInvitationCodeNotFound)
	})

	t.Run("empty invitation code", func(t *testing.T) {
		_, err := service.GetGroupByInvitation(ctx, "")
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrInvitationCodeNotFound)
	})

	t.Run("whitespace-only invitation code", func(t *testing.T) {
		_, err := service.GetGroupByInvitation(ctx, "   ")
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrInvitationCodeNotFound)
	})
}

func TestService_JoinGroup(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create admin user
	admin, err := client.User.Create().
		SetNickname("AdminUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create another user who will join
	joiner, err := client.User.Create().
		SetNickname("JoinerUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// Create a group with admin
	groupResult, err := service.CreateGroup(ctx, admin.ID, "TestFamily")
	require.NoError(t, err)

	// Generate invitation code
	code, err := service.GenerateInvitationCode(ctx, groupResult.Group.ID)
	require.NoError(t, err)

	t.Run("successful join", func(t *testing.T) {
		result, err := service.JoinGroup(ctx, code, joiner.ID)
		require.NoError(t, err)

		assert.Equal(t, groupResult.Group.ID, result.Group.ID)
		assert.Equal(t, joiner.ID, result.Member.UserID)
		assert.Equal(t, groupmember.RoleMember, result.Member.Role)
		assert.Equal(t, 2, result.MemberCount) // Admin + new member
	})

	t.Run("already a member", func(t *testing.T) {
		_, err := service.JoinGroup(ctx, code, joiner.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrAlreadyMember)
	})

	t.Run("invalid invitation code", func(t *testing.T) {
		_, err := service.JoinGroup(ctx, "XXXXXX", joiner.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrInvitationCodeNotFound)
	})

	t.Run("empty invitation code", func(t *testing.T) {
		_, err := service.JoinGroup(ctx, "", joiner.ID)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrInvitationCodeNotFound)
	})

	t.Run("non-existent user", func(t *testing.T) {
		_, err := service.JoinGroup(ctx, code, 99999)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrUserNotFound)
	})

	t.Run("case insensitive code", func(t *testing.T) {
		// Create a new user to test case insensitivity
		user3, err := client.User.Create().
			SetNickname("User3").
			SetPasswordHash("hash").
			Save(ctx)
		require.NoError(t, err)

		result, err := service.JoinGroup(ctx, strings.ToLower(code), user3.ID)
		require.NoError(t, err)
		assert.Equal(t, groupResult.Group.ID, result.Group.ID)
	})
}

func TestService_GetUserGroups(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create users
	user1, err := client.User.Create().
		SetNickname("User1").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	user2, err := client.User.Create().
		SetNickname("User2").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	t.Run("user with no groups returns empty list", func(t *testing.T) {
		groups, err := service.GetUserGroups(ctx, user1.ID)
		require.NoError(t, err)
		assert.Empty(t, groups)
	})

	t.Run("user with one group as admin", func(t *testing.T) {
		// Create a group
		groupResult, err := service.CreateGroup(ctx, user1.ID, "Family1")
		require.NoError(t, err)

		groups, err := service.GetUserGroups(ctx, user1.ID)
		require.NoError(t, err)
		assert.Len(t, groups, 1)
		assert.Equal(t, groupResult.Group.ID, groups[0].Group.ID)
		assert.Equal(t, "Family1", groups[0].Group.Name)
		assert.Equal(t, groupmember.RoleAdmin, groups[0].Role)
	})

	t.Run("user with multiple groups", func(t *testing.T) {
		// Create another group
		_, err := service.CreateGroup(ctx, user1.ID, "Family2")
		require.NoError(t, err)

		groups, err := service.GetUserGroups(ctx, user1.ID)
		require.NoError(t, err)
		assert.Len(t, groups, 2)
	})

	t.Run("user joined as member", func(t *testing.T) {
		// Create a group with user1 as admin
		groupResult, err := service.CreateGroup(ctx, user1.ID, "Family3")
		require.NoError(t, err)

		// Generate invitation code and have user2 join
		code, err := service.GenerateInvitationCode(ctx, groupResult.Group.ID)
		require.NoError(t, err)

		_, err = service.JoinGroup(ctx, code, user2.ID)
		require.NoError(t, err)

		// Check user2's groups
		groups, err := service.GetUserGroups(ctx, user2.ID)
		require.NoError(t, err)
		assert.Len(t, groups, 1)
		assert.Equal(t, groupResult.Group.ID, groups[0].Group.ID)
		assert.Equal(t, groupmember.RoleMember, groups[0].Role)
	})

	t.Run("non-existent user returns error", func(t *testing.T) {
		_, err := service.GetUserGroups(ctx, 99999)
		assert.Error(t, err)
		assert.ErrorIs(t, err, group.ErrUserNotFound)
	})
}
