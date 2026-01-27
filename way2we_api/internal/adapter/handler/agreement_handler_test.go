package handler_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/agreement"
	"github.com/way2we/way2we_api/internal/app/group"

	_ "github.com/mattn/go-sqlite3"
)

func TestAgreementHandler_ListAgreementsIncludesPinned(t *testing.T) {
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

	agreementPinned, err := client.Agreement.Create().
		SetName("Pinned Agreement").
		SetPoints(10).
		SetGroupID(groupEntity.ID).
		SetCreatorID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	agreementUnpinned, err := client.Agreement.Create().
		SetName("Regular Agreement").
		SetPoints(5).
		SetGroupID(groupEntity.ID).
		SetCreatorID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	err = client.User.UpdateOneID(user.ID).
		AddPinnedAgreementIDs(agreementPinned.ID).
		Exec(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	agreementService := agreement.NewService(client, groupService)
	h := handler.NewAgreementHandler(agreementService)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID))
	c.Set("user_id", user.ID)

	err = h.ListAgreements(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var response struct {
		Agreements []struct {
			ID       int  `json:"id"`
			IsPinned bool `json:"is_pinned"`
		} `json:"agreements"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &response))
	require.Len(t, response.Agreements, 2)

	pinnedByID := make(map[int]bool)
	for _, item := range response.Agreements {
		pinnedByID[item.ID] = item.IsPinned
	}

	assert.True(t, pinnedByID[agreementPinned.ID])
	assert.False(t, pinnedByID[agreementUnpinned.ID])
}

func TestAgreementHandler_PinAgreement(t *testing.T) {
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

	agreementEntity, err := client.Agreement.Create().
		SetName("Agreement").
		SetPoints(10).
		SetGroupID(groupEntity.ID).
		SetCreatorID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	agreementService := agreement.NewService(client, groupService)
	h := handler.NewAgreementHandler(agreementService)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/pin")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(agreementEntity.ID))
	c.Set("user_id", user.ID)

	err = h.PinAgreement(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	refreshedUser, err := client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedIDs, err := refreshedUser.QueryPinnedAgreements().IDs(ctx)
	require.NoError(t, err)
	require.Len(t, pinnedIDs, 1)
	assert.Equal(t, agreementEntity.ID, pinnedIDs[0])
}

func TestAgreementHandler_PinAgreement_NotMember(t *testing.T) {
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

	agreementEntity, err := client.Agreement.Create().
		SetName("Agreement").
		SetPoints(10).
		SetGroupID(groupEntity.ID).
		SetCreatorID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	agreementService := agreement.NewService(client, groupService)
	h := handler.NewAgreementHandler(agreementService)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/pin")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(agreementEntity.ID))
	c.Set("user_id", user.ID)

	err = h.PinAgreement(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusForbidden, rec.Code)

	var resp struct {
		Code string `json:"code"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	assert.Equal(t, "ERR_PIN_AGREEMENT_NOT_MEMBER", resp.Code)
}

func TestAgreementHandler_UnpinAgreement(t *testing.T) {
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

	agreementEntity, err := client.Agreement.Create().
		SetName("Agreement").
		SetPoints(10).
		SetGroupID(groupEntity.ID).
		SetCreatorID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	err = client.User.UpdateOneID(user.ID).
		AddPinnedAgreementIDs(agreementEntity.ID).
		Exec(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	agreementService := agreement.NewService(client, groupService)
	h := handler.NewAgreementHandler(agreementService)

	e := echo.New()
	req := httptest.NewRequest(http.MethodDelete, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/pin")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(agreementEntity.ID))
	c.Set("user_id", user.ID)

	err = h.UnpinAgreement(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	refreshedUser, err := client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedIDs, err := refreshedUser.QueryPinnedAgreements().IDs(ctx)
	require.NoError(t, err)
	assert.Empty(t, pinnedIDs)
}

func TestAgreementHandler_UnpinAgreement_NotFound(t *testing.T) {
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

	groupService := group.NewService(client)
	agreementService := agreement.NewService(client, groupService)
	h := handler.NewAgreementHandler(agreementService)

	e := echo.New()
	req := httptest.NewRequest(http.MethodDelete, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/pin")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), "9999")
	c.Set("user_id", user.ID)

	err = h.UnpinAgreement(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusNotFound, rec.Code)

	var resp struct {
		Code string `json:"code"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	assert.Equal(t, "ERR_UNPIN_AGREEMENT_NOT_FOUND", resp.Code)
}
