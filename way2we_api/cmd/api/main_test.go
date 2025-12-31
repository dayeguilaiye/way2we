package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
)

func TestHealthCheck(t *testing.T) {
	// Setup
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	c := e.NewContext(req, rec)

	// Handler
	handler := func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "UP"})
	}

	// Assertions
	if assert.NoError(t, handler(c)) {
		assert.Equal(t, http.StatusOK, rec.Code)

		var response map[string]string
		err := json.Unmarshal(rec.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, "UP", response["status"])
	}
}
