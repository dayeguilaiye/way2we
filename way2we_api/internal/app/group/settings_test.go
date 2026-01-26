package group_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/internal/app/group"

	_ "github.com/mattn/go-sqlite3"
)

func TestService_GroupSettingsDefaults(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	service := group.NewService(client)
	ctx := context.Background()

	// Create user
	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	t.Run("default settings values upon creation", func(t *testing.T) {
		result, err := service.CreateGroup(ctx, user.ID, "SettingsGroup")
		require.NoError(t, err)

		// Get from DB to be sure
		g, err := client.Group.Get(ctx, result.Group.ID)
		require.NoError(t, err)

		// Assert defaults
		assert.Equal(t, true, g.RequireConfirmationDefault, "RequireConfirmationDefault should be true")
		assert.Equal(t, false, g.AutoCompleteRedemptionDefault, "AutoCompleteRedemptionDefault should be false")
		assert.Equal(t, false, g.AutoFulfillRedemptionDefault, "AutoFulfillRedemptionDefault should be false")
		assert.Equal(t, 0, g.ProviderIncentiveRatio, "ProviderIncentiveRatio should be 0")
	})

	t.Run("update settings", func(t *testing.T) {
		// Create admin user
		admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("valid").Save(ctx)
		require.NoError(t, err)

		gResult, err := service.CreateGroup(ctx, admin.ID, "UpdateGroup")
		require.NoError(t, err)

		newSettings := group.SettingsUpdate{
			RequireConfirmationDefault:    false,
			AutoCompleteRedemptionDefault: true,
			AutoFulfillRedemptionDefault:  true,
			ProviderIncentiveRatio:        10,
		}

		updated, err := service.UpdateGroupSettings(ctx, admin.ID, gResult.Group.ID, newSettings)
		require.NoError(t, err)
		require.NotNil(t, updated)

		assert.Equal(t, false, updated.RequireConfirmationDefault)
		assert.Equal(t, true, updated.AutoCompleteRedemptionDefault)
		assert.Equal(t, true, updated.AutoFulfillRedemptionDefault)
		assert.Equal(t, 10, updated.ProviderIncentiveRatio)
	})
}
