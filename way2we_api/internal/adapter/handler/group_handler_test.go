package handler_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/way2we/way2we_api/ent/enttest"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/group"

	_ "github.com/mattn/go-sqlite3"
)

func TestGroupHandler_CreateGroup(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	// Create user
	u, err := client.User.Create().SetNickname("TestUser").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	groupService := group.NewService(client)
	h := handler.NewGroupHandler(groupService)

	t.Run("successful group creation", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"name": "我的家庭"}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)

		// Inject user ID into context (simulating JWT middleware)
		c.Set("user_id", u.ID)

		// Execute
		err := h.CreateGroup(c)

		// Assert
		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusOK, rec.Code)

			var response map[string]interface{}
			json.Unmarshal(rec.Body.Bytes(), &response)

			assert.Equal(t, "我的家庭", response["name"])
			assert.Equal(t, "admin", response["role"])
			assert.NotNil(t, response["id"])
		}
	})

	t.Run("empty name", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"name": ""}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", u.ID)

		err := h.CreateGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusBadRequest, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_NAME_REQUIRED")
		}
	})

	t.Run("name too long", func(t *testing.T) {
		e := echo.New()
		longName := strings.Repeat("a", 31)
		reqBody := map[string]string{"name": longName}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", u.ID)

		err := h.CreateGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusBadRequest, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_NAME_TOO_LONG")
		}
	})

	t.Run("unauthorized - no user_id", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"name": "Test"}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		// Do NOT set user_id

		err := h.CreateGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusUnauthorized, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_UNAUTHORIZED")
		}
	})

	t.Run("invalid request format", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodPost, "/v1/groups", bytes.NewReader([]byte("invalid json")))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", u.ID)

		err := h.CreateGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusBadRequest, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_INVALID_REQUEST")
		}
	})
}

func TestGroupHandler_GetInvitation(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	// Create users
	admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	other, err := client.User.Create().SetNickname("Other").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	groupService := group.NewService(client)
	h := handler.NewGroupHandler(groupService)

	// Create a group with admin
	result, err := groupService.CreateGroup(t.Context(), admin.ID, "TestGroup")
	require.NoError(t, err)

	t.Run("admin can get invitation code", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/invitation")
		c.SetParamNames("id")
		c.SetParamValues(fmt.Sprintf("%d", result.Group.ID))
		c.Set("user_id", admin.ID)

		err := h.GetInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusOK, rec.Code)

			var response map[string]interface{}
			json.Unmarshal(rec.Body.Bytes(), &response)

			assert.NotNil(t, response["invitation_code"])
			assert.Equal(t, float64(result.Group.ID), response["group_id"])
			assert.Contains(t, response["share_url"].(string), "way2we.app/join/")
		}
	})

	t.Run("non-admin cannot get invitation code", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/invitation")
		c.SetParamNames("id")
		c.SetParamValues(fmt.Sprintf("%d", result.Group.ID))
		c.Set("user_id", other.ID)

		err := h.GetInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusForbidden, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_NOT_ADMIN")
		}
	})

	t.Run("invalid group ID", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/invitation")
		c.SetParamNames("id")
		c.SetParamValues("invalid")
		c.Set("user_id", admin.ID)

		err := h.GetInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusBadRequest, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_INVALID_GROUP_ID")
		}
	})

	t.Run("unauthorized", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/invitation")
		c.SetParamNames("id")
		c.SetParamValues(fmt.Sprintf("%d", result.Group.ID))
		// No user_id set

		err := h.GetInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusUnauthorized, rec.Code)
		}
	})
}

func TestGroupHandler_RefreshInvitation(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	// Create admin user
	admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	groupService := group.NewService(client)
	h := handler.NewGroupHandler(groupService)

	// Create a group
	result, err := groupService.CreateGroup(t.Context(), admin.ID, "TestGroup")
	require.NoError(t, err)

	// Get initial code
	initialCode, err := groupService.GetInvitationCode(t.Context(), result.Group.ID, admin.ID)
	require.NoError(t, err)

	t.Run("admin can refresh invitation code", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodPost, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/:id/invitation/refresh")
		c.SetParamNames("id")
		c.SetParamValues(fmt.Sprintf("%d", result.Group.ID))
		c.Set("user_id", admin.ID)

		err := h.RefreshInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusOK, rec.Code)

			var response map[string]interface{}
			json.Unmarshal(rec.Body.Bytes(), &response)

			newCode := response["invitation_code"].(string)
			assert.NotEqual(t, initialCode, newCode)
		}
	})
}

func TestGroupHandler_GetGroupByInvitation(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	// Create user
	u, err := client.User.Create().SetNickname("User").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	groupService := group.NewService(client)
	h := handler.NewGroupHandler(groupService)

	// Create a group and get invitation code
	result, err := groupService.CreateGroup(t.Context(), u.ID, "MyFamily")
	require.NoError(t, err)

	code, err := groupService.GenerateInvitationCode(t.Context(), result.Group.ID)
	require.NoError(t, err)

	t.Run("get group by valid invitation code", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/by-invitation/:code")
		c.SetParamNames("code")
		c.SetParamValues(code)

		err := h.GetGroupByInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusOK, rec.Code)

			var response map[string]interface{}
			json.Unmarshal(rec.Body.Bytes(), &response)

			assert.Equal(t, "MyFamily", response["name"])
			assert.Equal(t, float64(1), response["member_count"])
		}
	})

	t.Run("invalid invitation code", func(t *testing.T) {
		e := echo.New()
		req := httptest.NewRequest(http.MethodGet, "/", nil)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.SetPath("/v1/groups/by-invitation/:code")
		c.SetParamNames("code")
		c.SetParamValues("XXXXXX")

		err := h.GetGroupByInvitation(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusNotFound, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_INVITATION_CODE_INVALID")
		}
	})
}

func TestGroupHandler_JoinGroup(t *testing.T) {
	client := enttest.Open(t, "sqlite3", "file:ent?mode=memory&cache=shared&_fk=1")
	defer client.Close()

	// Create users
	admin, err := client.User.Create().SetNickname("Admin").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	joiner, err := client.User.Create().SetNickname("Joiner").SetPasswordHash("hash").Save(t.Context())
	require.NoError(t, err)

	groupService := group.NewService(client)
	h := handler.NewGroupHandler(groupService)

	// Create a group and get invitation code
	result, err := groupService.CreateGroup(t.Context(), admin.ID, "TestFamily")
	require.NoError(t, err)

	code, err := groupService.GenerateInvitationCode(t.Context(), result.Group.ID)
	require.NoError(t, err)

	t.Run("successful join", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"invitation_code": code}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups/join", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", joiner.ID)

		err := h.JoinGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusOK, rec.Code)

			var response map[string]interface{}
			json.Unmarshal(rec.Body.Bytes(), &response)

			group := response["group"].(map[string]interface{})
			assert.Equal(t, "TestFamily", group["name"])
			assert.Equal(t, "member", group["role"])
			assert.Equal(t, float64(2), group["member_count"])
		}
	})

	t.Run("already a member", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"invitation_code": code}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups/join", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", joiner.ID)

		err := h.JoinGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusBadRequest, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_ALREADY_MEMBER")
		}
	})

	t.Run("invalid invitation code", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"invitation_code": "XXXXXX"}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups/join", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", joiner.ID)

		err := h.JoinGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusNotFound, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_INVITATION_CODE_INVALID")
		}
	})

	t.Run("empty invitation code", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"invitation_code": ""}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups/join", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		c.Set("user_id", joiner.ID)

		err := h.JoinGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusBadRequest, rec.Code)
			assert.Contains(t, rec.Body.String(), "ERR_INVITATION_CODE_REQUIRED")
		}
	})

	t.Run("unauthorized", func(t *testing.T) {
		e := echo.New()
		reqBody := map[string]string{"invitation_code": code}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/v1/groups/join", bytes.NewReader(body))
		req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
		rec := httptest.NewRecorder()
		c := e.NewContext(req, rec)
		// No user_id set

		err := h.JoinGroup(c)

		if assert.NoError(t, err) {
			assert.Equal(t, http.StatusUnauthorized, rec.Code)
		}
	})
}
