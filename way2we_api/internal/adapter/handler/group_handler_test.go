package handler_test

import (
	"bytes"
	"encoding/json"
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
