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
