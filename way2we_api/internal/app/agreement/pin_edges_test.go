package agreement_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"

	_ "github.com/mattn/go-sqlite3"
)

func TestAgreementPinnedEdge(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	ctx := context.Background()

	user, err := client.User.Create().
		SetNickname("TestUser").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	group, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	agreement, err := client.Agreement.Create().
		SetName("TestAgreement").
		SetPoints(10).
		SetGroupID(group.ID).
		SetCreatorID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	err = client.User.UpdateOneID(user.ID).
		AddPinnedAgreementIDs(agreement.ID).
		Exec(ctx)
	require.NoError(t, err)

	refreshedUser, err := client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedAgreementIDs, err := refreshedUser.QueryPinnedAgreements().IDs(ctx)
	require.NoError(t, err)
	require.Len(t, pinnedAgreementIDs, 1)
	require.Equal(t, agreement.ID, pinnedAgreementIDs[0])

	refreshedAgreement, err := client.Agreement.Get(ctx, agreement.ID)
	require.NoError(t, err)

	pinnedByUserIDs, err := refreshedAgreement.QueryPinnedByUsers().IDs(ctx)
	require.NoError(t, err)
	require.Len(t, pinnedByUserIDs, 1)
	require.Equal(t, user.ID, pinnedByUserIDs[0])
}
