package handler_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/agreement"
	entcompletion "github.com/way2we/way2we_api/ent/agreementcompletion"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/agreementcompletion"
	"github.com/way2we/way2we_api/internal/app/group"
	"github.com/way2we/way2we_api/internal/app/points"

	_ "github.com/mattn/go-sqlite3"
)

type completionTestSetup struct {
	client    *ent.Client
	handler   *handler.AgreementCompletionHandler
	service   *agreementcompletion.Service
	group     *ent.Group
	recorder  *ent.User
	completer *ent.User
	confirmer *ent.User
	agreement *ent.Agreement
}

func setupAgreementCompletionHandler(t *testing.T, requireConfirmation bool) *completionTestSetup {
	t.Helper()

	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")
	ctx := t.Context()

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

	confirmer, err := client.User.Create().
		SetNickname("Confirmer").
		SetPasswordHash("hash").
		Save(ctx)
	require.NoError(t, err)

	_, err = client.GroupMember.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(recorder.ID).
		SetRole(groupmember.RoleMember).
		SetPermissions([]string{group.PermissionRecordForOthers}).
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
		SetUserID(confirmer.ID).
		SetRole(groupmember.RoleMember).
		Save(ctx)
	require.NoError(t, err)

	agr, err := client.Agreement.Create().
		SetName("Agreement").
		SetPoints(10).
		SetGroupID(groupEntity.ID).
		SetCreatorID(recorder.ID).
		SetStatus(agreement.StatusActive).
		SetRequireConfirmation(requireConfirmation).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	pointsService := points.NewService(client)
	completionService := agreementcompletion.NewService(client, groupService, pointsService)
	h := handler.NewAgreementCompletionHandler(completionService)

	return &completionTestSetup{
		client:    client,
		handler:   h,
		service:   completionService,
		group:     groupEntity,
		recorder:  recorder,
		completer: completer,
		confirmer: confirmer,
		agreement: agr,
	}
}

func TestAgreementCompletionHandler_CreateCompletion_Pending(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	body := map[string]interface{}{
		"completer_id": setup.completer.ID,
	}
	payload, err := json.Marshal(body)
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/v1/groups/:groupId/agreements/:agreementId/completions", bytes.NewReader(payload))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/completions")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(setup.group.ID), strconv.Itoa(setup.agreement.ID))
	c.Set("user_id", setup.recorder.ID)

	err = setup.handler.CreateCompletion(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	var resp struct {
		Completion struct {
			Status string `json:"status"`
		} `json:"completion"`
		Message string `json:"message"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.Equal(t, "pending", resp.Completion.Status)
	require.Equal(t, "已提交，等待确认", resp.Message)
}

func TestAgreementCompletionHandler_CreateCompletion_EmptyBodyDefaultsSelf(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	e := echo.New()
	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/groups/:groupId/agreements/:agreementId/completions",
		nil,
	)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/completions")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(setup.group.ID), strconv.Itoa(setup.agreement.ID))
	c.Set("user_id", setup.recorder.ID)

	err := setup.handler.CreateCompletion(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	var resp struct {
		Completion struct {
			CompleterID int `json:"completer_id"`
		} `json:"completion"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.Equal(t, setup.recorder.ID, resp.Completion.CompleterID)
}

func TestAgreementCompletionHandler_CreateCompletion_NotMember(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	nonMember, err := setup.client.User.Create().
		SetNickname("NonMember").
		SetPasswordHash("hash").
		Save(t.Context())
	require.NoError(t, err)

	body := map[string]interface{}{}
	payload, err := json.Marshal(body)
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/v1/groups/:groupId/agreements/:agreementId/completions", bytes.NewReader(payload))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreements/:agreementId/completions")
	c.SetParamNames("groupId", "agreementId")
	c.SetParamValues(strconv.Itoa(setup.group.ID), strconv.Itoa(setup.agreement.ID))
	c.Set("user_id", nonMember.ID)

	err = setup.handler.CreateCompletion(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusForbidden, rec.Code)

	var resp struct {
		Code string `json:"code"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.Equal(t, "ERR_COMPLETION_NOT_MEMBER", resp.Code)
}

func TestAgreementCompletionHandler_ListCompletions(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	_, err := setup.service.CreateCompletion(
		t.Context(),
		setup.group.ID,
		setup.agreement.ID,
		setup.recorder.ID,
		setup.completer.ID,
	)
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/agreement-completions?status=pending", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreement-completions")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(setup.group.ID))
	c.Set("user_id", setup.recorder.ID)

	err = setup.handler.ListCompletions(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	var resp struct {
		Completions []struct {
			AgreementName string `json:"agreement_name"`
		} `json:"completions"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.Len(t, resp.Completions, 1)
	require.Equal(t, "Agreement", resp.Completions[0].AgreementName)
}

func TestAgreementCompletionHandler_ConfirmCompletion(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	completion, err := setup.service.CreateCompletion(
		t.Context(),
		setup.group.ID,
		setup.agreement.ID,
		setup.recorder.ID,
		setup.completer.ID,
	)
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/v1/groups/:groupId/agreement-completions/:id/confirm", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreement-completions/:id/confirm")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(setup.group.ID), strconv.Itoa(completion.ID))
	c.Set("user_id", setup.confirmer.ID)

	err = setup.handler.ConfirmCompletion(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	fresh, err := setup.client.AgreementCompletion.Get(t.Context(), completion.ID)
	require.NoError(t, err)
	require.Equal(t, entcompletion.StatusConfirmed, fresh.Status)

	logCount, err := setup.client.PointLog.Query().Count(t.Context())
	require.NoError(t, err)
	require.Equal(t, 1, logCount)
}

func TestAgreementCompletionHandler_RejectCompletion(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	completion, err := setup.service.CreateCompletion(
		t.Context(),
		setup.group.ID,
		setup.agreement.ID,
		setup.recorder.ID,
		setup.completer.ID,
	)
	require.NoError(t, err)

	body := map[string]string{"reason": "不符合要求"}
	payload, err := json.Marshal(body)
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/v1/groups/:groupId/agreement-completions/:id/reject", bytes.NewReader(payload))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreement-completions/:id/reject")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(setup.group.ID), strconv.Itoa(completion.ID))
	c.Set("user_id", setup.confirmer.ID)

	err = setup.handler.RejectCompletion(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	fresh, err := setup.client.AgreementCompletion.Get(t.Context(), completion.ID)
	require.NoError(t, err)
	require.Equal(t, entcompletion.StatusRejected, fresh.Status)
	require.Equal(t, "不符合要求", fresh.RejectedReason)
}

func TestAgreementCompletionHandler_RejectCompletion_EmptyBody(t *testing.T) {
	setup := setupAgreementCompletionHandler(t, true)
	defer setup.client.Close()

	completion, err := setup.service.CreateCompletion(
		t.Context(),
		setup.group.ID,
		setup.agreement.ID,
		setup.recorder.ID,
		setup.completer.ID,
	)
	require.NoError(t, err)

	e := echo.New()
	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/groups/:groupId/agreement-completions/:id/reject",
		nil,
	)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/agreement-completions/:id/reject")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(setup.group.ID), strconv.Itoa(completion.ID))
	c.Set("user_id", setup.confirmer.ID)

	err = setup.handler.RejectCompletion(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	fresh, err := setup.client.AgreementCompletion.Get(t.Context(), completion.ID)
	require.NoError(t, err)
	require.Equal(t, entcompletion.StatusRejected, fresh.Status)
	require.Empty(t, fresh.RejectedReason)
}
