package user_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/internal/app/user"

	_ "github.com/mattn/go-sqlite3"
)

func TestService_UpdateProfile(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := user.NewService(client)
	ctx := context.Background()

	// 1. Create a user manually
	u, err := client.User.Create().
		SetNickname("OldName").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	// 2. Update Nickname
	newName := "NewName"
	updatedUser, err := service.UpdateProfile(ctx, u.ID, &newName, nil)
	require.NoError(t, err)
	assert.Equal(t, newName, updatedUser.Nickname)

	// 3. Verify DB
	dbUser, err := client.User.Get(ctx, u.ID)
	require.NoError(t, err)
	assert.Equal(t, newName, dbUser.Nickname)

	// 4. Update Avatar
	newAvatar := "http://example.com/avatar.jpg"
	updatedUser, err = service.UpdateProfile(ctx, u.ID, nil, &newAvatar)
	require.NoError(t, err)
	assert.Equal(t, newAvatar, updatedUser.Avatar)

	// 5. Update Both
	name2 := "Name2"
	avatar2 := "http://ex.com/2.jpg"
	updatedUser, err = service.UpdateProfile(ctx, u.ID, &name2, &avatar2)
	require.NoError(t, err)
	assert.Equal(t, name2, updatedUser.Nickname)
	assert.Equal(t, avatar2, updatedUser.Avatar)

	// 6. Validation Error (Nickname too long)
	longName := "ThisNameIsWayTooLongForTheLimitAndShouldFail"
	_, err = service.UpdateProfile(ctx, u.ID, &longName, nil)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "cannot exceed 20 characters")
}
