package agreementcompletion_test

import (
	"context"
	"sync"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/agreement"
	entcompletion "github.com/way2we/way2we_api/ent/agreementcompletion"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/app/agreementcompletion"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/app/points"

	_ "github.com/mattn/go-sqlite3"
)

func setupAgreementCompletionService(t *testing.T) (*ent.Client, *agreementcompletion.Service, context.Context, *ent.Group, *ent.User, *ent.User, *ent.User, *ent.User) {
	t.Helper()

	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")

	ctx := context.Background()

	groupEntity, err := client.Group.Create().
		SetName("TestGroup").
		Save(ctx)
	require.NoError(t, err)

	recorder, err := client.User.Create().
		SetNickname("Recorder").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	completer, err := client.User.Create().
		SetNickname("Completer").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	confirmerA, err := client.User.Create().
		SetNickname("ConfirmerA").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	confirmerB, err := client.User.Create().
		SetNickname("ConfirmerB").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(recorder.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(completer.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(confirmerA.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(confirmerB.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	pointsService := points.NewService(client)
	service := agreementcompletion.NewService(client, groupService, pointsService)

	return client, service, ctx, groupEntity, recorder, completer, confirmerA, confirmerB
}

func createAgreement(t *testing.T, ctx context.Context, client *ent.Client, groupID int, creatorID int, requireConfirmation bool, applicable []int) *ent.Agreement {
	t.Helper()

	builder := client.Agreement.Create().
		SetName("Agreement").
		SetPoints(10).
		SetGroupID(groupID).
		SetCreatorID(creatorID).
		SetStatus(agreement.StatusActive).
		SetRequireConfirmation(requireConfirmation)

	if applicable != nil {
		builder = builder.SetApplicableMemberIds(applicable)
	}

	agr, err := builder.Save(ctx)
	require.NoError(t, err)
	return agr
}

func TestCreateCompletion_RecordForOthersPermission(t *testing.T) {
	client, service, ctx, groupEntity, recorder, completer, _, _ := setupAgreementCompletionService(t)
	defer client.Close()

	agr := createAgreement(t, ctx, client, groupEntity.ID, recorder.ID, true, nil)

	_, err := service.CreateCompletion(ctx, groupEntity.ID, agr.ID, recorder.ID, completer.ID)
	require.ErrorIs(t, err, agreementcompletion.ErrPermissionDenied)

	_, err = client.GroupMember.Update().
		Where(
			groupmember.GroupID(groupEntity.ID),
			groupmember.UserID(recorder.ID),
		).
		SetPermissions([]string{group.PermissionRecordForOthers}).
		Save(ctx)
	require.NoError(t, err)

	completion, err := service.CreateCompletion(ctx, groupEntity.ID, agr.ID, recorder.ID, completer.ID)
	require.NoError(t, err)
	require.Equal(t, completer.ID, completion.CompleterID)
}

func TestCreateCompletion_ApplicableMemberCheck(t *testing.T) {
	client, service, ctx, groupEntity, recorder, completer, _, _ := setupAgreementCompletionService(t)
	defer client.Close()

	agr := createAgreement(t, ctx, client, groupEntity.ID, recorder.ID, true, []int{recorder.ID})

	_, err := client.GroupMember.Update().
		Where(
			groupmember.GroupID(groupEntity.ID),
			groupmember.UserID(recorder.ID),
		).
		SetPermissions([]string{group.PermissionRecordForOthers}).
		Save(ctx)
	require.NoError(t, err)

	_, err = service.CreateCompletion(ctx, groupEntity.ID, agr.ID, recorder.ID, completer.ID)
	require.ErrorIs(t, err, agreementcompletion.ErrCompleterNotApplicable)
}

func TestConfirm_SelfConfirmForbidden(t *testing.T) {
	client, service, ctx, groupEntity, recorder, _, _, _ := setupAgreementCompletionService(t)
	defer client.Close()

	agr := createAgreement(t, ctx, client, groupEntity.ID, recorder.ID, true, nil)

	completion, err := service.CreateCompletion(ctx, groupEntity.ID, agr.ID, recorder.ID, recorder.ID)
	require.NoError(t, err)

	err = service.Confirm(ctx, groupEntity.ID, completion.ID, recorder.ID)
	require.ErrorIs(t, err, agreementcompletion.ErrCannotSelfConfirm)
}

func TestConfirm_AtomicityRollbackOnPointsFailure(t *testing.T) {
	client, service, ctx, groupEntity, recorder, _, confirmerA, _ := setupAgreementCompletionService(t)
	defer client.Close()

	agr := createAgreement(t, ctx, client, groupEntity.ID, recorder.ID, true, nil)

	completion, err := service.CreateCompletion(ctx, groupEntity.ID, agr.ID, recorder.ID, recorder.ID)
	require.NoError(t, err)

	_, err = client.GroupMember.Delete().
		Where(
			groupmember.GroupID(groupEntity.ID),
			groupmember.UserID(recorder.ID),
		).
		Exec(ctx)
	require.NoError(t, err)

	err = service.Confirm(ctx, groupEntity.ID, completion.ID, confirmerA.ID)
	require.Error(t, err)

	fresh, err := client.AgreementCompletion.Get(ctx, completion.ID)
	require.NoError(t, err)
	require.Equal(t, entcompletion.StatusPending, fresh.Status)

	logCount, err := client.PointLog.Query().Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 0, logCount)
}

func TestConfirm_ConcurrentConfirmationNoDuplicatePoints(t *testing.T) {
	client, service, ctx, groupEntity, recorder, _, confirmerA, confirmerB := setupAgreementCompletionService(t)
	defer client.Close()

	agr := createAgreement(t, ctx, client, groupEntity.ID, recorder.ID, true, nil)

	completion, err := service.CreateCompletion(ctx, groupEntity.ID, agr.ID, recorder.ID, recorder.ID)
	require.NoError(t, err)

	var wg sync.WaitGroup
	errs := make([]error, 2)

	wg.Add(2)
	go func() {
		defer wg.Done()
		errs[0] = service.Confirm(ctx, groupEntity.ID, completion.ID, confirmerA.ID)
	}()
	go func() {
		defer wg.Done()
		errs[1] = service.Confirm(ctx, groupEntity.ID, completion.ID, confirmerB.ID)
	}()
	wg.Wait()

	successCount := 0
	for _, err := range errs {
		if err == nil {
			successCount++
		}
	}
	require.Equal(t, 1, successCount)

	logCount, err := client.PointLog.Query().Count(ctx)
	require.NoError(t, err)
	require.Equal(t, 1, logCount)

	completion, err = client.AgreementCompletion.Query().
		Where(entcompletion.ID(completion.ID)).
		Only(ctx)
	require.NoError(t, err)
	require.Equal(t, entcompletion.StatusConfirmed, completion.Status)

}
