package handler_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/points"

	_ "github.com/mattn/go-sqlite3"
)

func setupPointsHandler(t *testing.T) (*ent.Client, *handler.PointsHandler, int, int) {
	t.Helper()

	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")

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

	service := points.NewService(client)
	h := handler.NewPointsHandler(service)

	return client, h, user.ID, groupEntity.ID
}

func TestPointsHandler_GetMyPoints(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")
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

	_, err = client.MemberSummary.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(user.ID).
		SetBalance(15).
		Save(ctx)
	require.NoError(t, err)

	service := points.NewService(client)
	h := handler.NewPointsHandler(service)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/me", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/me")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID))
	c.Set("user_id", user.ID)

	err = h.GetMyPoints(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	var resp struct {
		Balance int `json:"balance"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.Equal(t, 15, resp.Balance)
}

func TestPointsHandler_GetMyPoints_Unauthorized(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")
	defer client.Close()

	service := points.NewService(client)
	h := handler.NewPointsHandler(service)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/me", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/me")
	c.SetParamNames("groupId")
	c.SetParamValues("1")

	err := h.GetMyPoints(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusUnauthorized, rec.Code)
}

func TestPointsHandler_GetMyPoints_NotMember(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")
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

	service := points.NewService(client)
	h := handler.NewPointsHandler(service)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/me", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/me")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID))
	c.Set("user_id", user.ID)

	err = h.GetMyPoints(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusForbidden, rec.Code)
}

func TestPointsHandler_ListPointLogs_DefaultMember(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1&_busy_timeout=5000")
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

	_, err = client.MemberSummary.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(user.ID).
		SetBalance(5).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.PointLog.Create().
		SetGroupID(groupEntity.ID).
		SetUserID(user.ID).
		SetDelta(5).
		SetBalanceAfter(5).
		SetSourceType("agreement").
		SetSourceID("agree-1").
		Save(ctx)
	require.NoError(t, err)

	service := points.NewService(client)
	h := handler.NewPointsHandler(service)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/logs", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/logs")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID))
	c.Set("user_id", user.ID)

	err = h.ListPointLogs(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusOK, rec.Code)

	var resp struct {
		Logs []struct {
			SourceType string `json:"source_type"`
		} `json:"logs"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
	require.Len(t, resp.Logs, 1)
	require.Equal(t, "agreement", resp.Logs[0].SourceType)
}

func TestPointsHandler_ListPointLogs_InvalidLimit(t *testing.T) {
	client, h, userID, groupID := setupPointsHandler(t)
	defer client.Close()

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/logs?limit=0", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/logs")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupID))
	c.Set("user_id", userID)

	err := h.ListPointLogs(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestPointsHandler_ListPointLogs_InvalidMemberID(t *testing.T) {
	client, h, userID, groupID := setupPointsHandler(t)
	defer client.Close()

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/logs?member_id=abc", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/logs")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupID))
	c.Set("user_id", userID)

	err := h.ListPointLogs(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestPointsHandler_ListPointLogs_InvalidTimeRange(t *testing.T) {
	client, h, userID, groupID := setupPointsHandler(t)
	defer client.Close()

	from := time.Now()
	to := from.Add(-time.Hour)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/v1/groups/:groupId/points/logs", nil)
	q := req.URL.Query()
	q.Set("from", from.Format(time.RFC3339))
	q.Set("to", to.Format(time.RFC3339))
	req.URL.RawQuery = q.Encode()

	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/points/logs")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupID))
	c.Set("user_id", userID)

	err := h.ListPointLogs(c)
	require.NoError(t, err)
	require.Equal(t, http.StatusBadRequest, rec.Code)
}
