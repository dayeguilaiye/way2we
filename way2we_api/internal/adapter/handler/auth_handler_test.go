package handler_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	adapterAuth "github.com/way2we/way2we_api/internal/adapter/auth"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/auth"
)

func setupTest() (*echo.Echo, *handler.AuthHandler) {
	e := echo.New()

	smsProvider := adapterAuth.NewLogSmsProvider()
	emailProvider := adapterAuth.NewLogEmailProvider()
	authService := auth.NewService(nil, smsProvider, emailProvider)

	h := handler.NewAuthHandler(authService)
	h.RegisterRoutes(e)

	return e, h
}

func TestSendVerificationCode_ValidPhone(t *testing.T) {
	e, _ := setupTest()

	reqBody := `{"type":"phone","target":"13800138000"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, rec.Body.String(), `"success":true`)
}

func TestSendVerificationCode_ValidEmail(t *testing.T) {
	e, _ := setupTest()

	reqBody := `{"type":"email","target":"test@example.com"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, rec.Body.String(), `"success":true`)
}

func TestSendVerificationCode_InvalidPhone(t *testing.T) {
	e, _ := setupTest()

	// Invalid phone number format
	reqBody := `{"type":"phone","target":"12345"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusBadRequest, rec.Code)
	assert.Contains(t, rec.Body.String(), "ERR_INVALID_TARGET")
}

func TestSendVerificationCode_InvalidEmail(t *testing.T) {
	e, _ := setupTest()

	// Invalid email format
	reqBody := `{"type":"email","target":"not-an-email"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusBadRequest, rec.Code)
	assert.Contains(t, rec.Body.String(), "ERR_INVALID_TARGET")
}

func TestSendVerificationCode_InvalidType(t *testing.T) {
	e, _ := setupTest()

	reqBody := `{"type":"invalid","target":"13800138000"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusBadRequest, rec.Code)
	assert.Contains(t, rec.Body.String(), "ERR_INVALID_TYPE")
}

func TestSendVerificationCode_EmptyBody(t *testing.T) {
	e, _ := setupTest()

	reqBody := `{}`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestSendVerificationCode_MalformedJSON(t *testing.T) {
	e, _ := setupTest()

	reqBody := `{invalid json`
	req := httptest.NewRequest(http.MethodPost, "/v1/auth/verification-code", strings.NewReader(reqBody))
	req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
	rec := httptest.NewRecorder()

	e.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusBadRequest, rec.Code)
}

func TestRouteRegistration(t *testing.T) {
	e, _ := setupTest()

	// Verify route is registered
	routes := e.Routes()
	found := false
	for _, r := range routes {
		if r.Path == "/v1/auth/verification-code" && r.Method == http.MethodPost {
			found = true
			break
		}
	}
	require.True(t, found, "Route /v1/auth/verification-code should be registered")
}
