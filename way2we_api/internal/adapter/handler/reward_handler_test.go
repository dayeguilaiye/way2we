package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"net/textproto"
	"strconv"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/ent/groupmember"
	"github.com/way2we/way2we_api/ent/reward"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/group"
	rewardsvc "github.com/way2we/way2we_api/internal/app/reward"
	"github.com/way2we/way2we_api/internal/pkg/validator"

	_ "github.com/mattn/go-sqlite3"
)

func TestRewardHandler_ListRewards_DefaultActive(t *testing.T) {
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

	_, err = client.Reward.Create().
		SetName("Active Reward").
		SetCostPoints(10).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.Reward.Create().
		SetName("Inactive Reward").
		SetCostPoints(20).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		SetStatus(reward.StatusInactive).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	rewardService := rewardsvc.NewService(client, groupService)
	h := handler.NewRewardHandler(rewardService, nil)

	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/rewards")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID))
	c.Set("user_id", user.ID)

	err = h.ListRewards(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var response struct {
		Rewards []struct {
			Status string `json:"status"`
		} `json:"rewards"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &response))
	require.Len(t, response.Rewards, 1)
	assert.Equal(t, "active", response.Rewards[0].Status)
}

func TestRewardHandler_CreateUpdateStatus(t *testing.T) {
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
	rewardService := rewardsvc.NewService(client, groupService)
	h := handler.NewRewardHandler(rewardService, nil)

	e := echo.New()

	// Create
	reqBody := map[string]any{
		"name":        "Reward A",
		"cost_points": 50,
	}
	body, _ := json.Marshal(reqBody)
	req := httptest.NewRequest(http.MethodPost, "/v1/groups/:groupId/rewards", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/rewards")
	c.SetParamNames("groupId")
	c.SetParamValues(strconv.Itoa(groupEntity.ID))
	c.Set("user_id", user.ID)

	err = h.CreateReward(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var created struct {
		ID int `json:"id"`
	}
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &created))

	// Update
	updateBody := map[string]any{"name": "Reward B"}
	body, _ = json.Marshal(updateBody)
	req = httptest.NewRequest(http.MethodPut, "/v1/groups/:groupId/rewards/:id", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec = httptest.NewRecorder()
	c = e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/rewards/:id")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(created.ID))
	c.Set("user_id", user.ID)

	err = h.UpdateReward(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	// Update status
	statusBody := map[string]any{"status": "inactive"}
	body, _ = json.Marshal(statusBody)
	req = httptest.NewRequest(http.MethodPut, "/v1/groups/:groupId/rewards/:id/status", bytes.NewReader(body))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec = httptest.NewRecorder()
	c = e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/rewards/:id/status")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(created.ID))
	c.Set("user_id", user.ID)

	err = h.UpdateRewardStatus(c)
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)
}

func TestRewardHandler_PinReward(t *testing.T) {
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

	rewardEntity, err := client.Reward.Create().
		SetName("Reward").
		SetCostPoints(10).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	rewardService := rewardsvc.NewService(client, groupService)
	h := handler.NewRewardHandler(rewardService, nil)

	e := echo.New()
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/rewards/:id/pin")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(rewardEntity.ID))
	c.Set("user_id", user.ID)

	err = h.PinReward(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	refreshedUser, err := client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedIDs, err := refreshedUser.QueryPinnedRewards().IDs(ctx)
	require.NoError(t, err)
	require.Len(t, pinnedIDs, 1)
	assert.Equal(t, rewardEntity.ID, pinnedIDs[0])
}

func TestRewardHandler_UnpinReward(t *testing.T) {
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

	rewardEntity, err := client.Reward.Create().
		SetName("Reward").
		SetCostPoints(10).
		SetGroupID(groupEntity.ID).
		SetProviderID(user.ID).
		Save(ctx)
	require.NoError(t, err)

	_, err = client.User.UpdateOneID(user.ID).
		AddPinnedRewardIDs(rewardEntity.ID).
		Save(ctx)
	require.NoError(t, err)

	groupService := group.NewService(client)
	rewardService := rewardsvc.NewService(client, groupService)
	h := handler.NewRewardHandler(rewardService, nil)

	e := echo.New()
	req := httptest.NewRequest(http.MethodDelete, "/", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.SetPath("/v1/groups/:groupId/rewards/:id/pin")
	c.SetParamNames("groupId", "id")
	c.SetParamValues(strconv.Itoa(groupEntity.ID), strconv.Itoa(rewardEntity.ID))
	c.Set("user_id", user.ID)

	err = h.UnpinReward(c)

	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	refreshedUser, err := client.User.Get(ctx, user.ID)
	require.NoError(t, err)

	pinnedIDs, err := refreshedUser.QueryPinnedRewards().IDs(ctx)
	require.NoError(t, err)
	require.Empty(t, pinnedIDs)
}

func TestRewardHandler_UploadRewardCover(t *testing.T) {
	mockStorage := &MockStorageProvider{
		UploadFunc: func(ctx context.Context, file io.Reader, filename string) (string, error) {
			return "reward123.jpg", nil
		},
		GetPublicUrlFunc: func(key string) string {
			return "http://localhost/uploads/" + key
		},
	}

	h := handler.NewRewardHandler(nil, mockStorage)
	e := echo.New()

	body := new(bytes.Buffer)
	writer := multipart.NewWriter(body)

	hPart := make(textproto.MIMEHeader)
	hPart.Set("Content-Disposition", `form-data; name="cover"; filename="test.jpg"`)
	hPart.Set("Content-Type", "image/jpeg")
	part, _ := writer.CreatePart(hPart)
	part.Write([]byte("fake image content"))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/v1/uploads/reward-cover", body)
	req.Header.Set(echo.HeaderContentType, writer.FormDataContentType())
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	c.Set("user_id", 1)

	err := h.UploadRewardCover(c)

	if assert.NoError(t, err) {
		assert.Equal(t, http.StatusOK, rec.Code)
		assert.Contains(t, rec.Body.String(), "http://localhost/uploads/reward123.jpg")
	}
}

func TestRewardHandler_UploadRewardCover_InvalidType(t *testing.T) {
	h := handler.NewRewardHandler(nil, nil)
	e := echo.New()

	body := new(bytes.Buffer)
	writer := multipart.NewWriter(body)

	hPart := make(textproto.MIMEHeader)
	hPart.Set("Content-Disposition", `form-data; name="cover"; filename="test.txt"`)
	hPart.Set("Content-Type", "text/plain")
	part, _ := writer.CreatePart(hPart)
	part.Write([]byte("not an image"))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/v1/uploads/reward-cover", body)
	req.Header.Set(echo.HeaderContentType, writer.FormDataContentType())
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.Set("user_id", 1)

	err := h.UploadRewardCover(c)

	if assert.NoError(t, err) {
		assert.Equal(t, http.StatusBadRequest, rec.Code)
		assert.Contains(t, rec.Body.String(), "ERR_INVALID_FILE")
	}
}

func TestRewardHandler_UploadRewardCover_TooLarge(t *testing.T) {
	h := handler.NewRewardHandler(nil, nil)
	e := echo.New()

	body := new(bytes.Buffer)
	writer := multipart.NewWriter(body)

	hPart := make(textproto.MIMEHeader)
	hPart.Set("Content-Disposition", `form-data; name="cover"; filename="big.jpg"`)
	hPart.Set("Content-Type", "image/jpeg")
	part, _ := writer.CreatePart(hPart)
	part.Write(bytes.Repeat([]byte("a"), validator.MaxImageSize+1))
	writer.Close()

	req := httptest.NewRequest(http.MethodPost, "/v1/uploads/reward-cover", body)
	req.Header.Set(echo.HeaderContentType, writer.FormDataContentType())
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)
	c.Set("user_id", 1)

	err := h.UploadRewardCover(c)

	if assert.NoError(t, err) {
		assert.Equal(t, http.StatusBadRequest, rec.Code)
		assert.Contains(t, rec.Body.String(), "ERR_INVALID_FILE")
	}
}
