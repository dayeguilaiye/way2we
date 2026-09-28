package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http/httptest"
	"strings"
	"testing"

	"way2we/server/internal/platform/logging"
)

func TestResponsesAndSafeLogs(t *testing.T) {
	var logs bytes.Buffer
	handler := New(logging.New(&logs, "test", "test"), func(context.Context) error { return nil }, true)
	cases := []struct {
		method, path, body, code string
		status                   int
	}{
		{"GET", "/health/ready", "", "", 200},
		{"POST", "/dev/validate", `{"quantity":0}`, "VALIDATION_FAILED", 422},
		{"POST", "/dev/validate", `{"quantity":2}`, "", 200},
		{"POST", "/dev/validate", `{"quantity":2} {}`, "INVALID_REQUEST", 400},
		{"GET", "/private/secret@example.com?token=supersecret", "", "NOT_FOUND", 404},
	}
	seen := map[string]bool{}
	for _, tc := range cases {
		req := httptest.NewRequest(tc.method, tc.path, strings.NewReader(tc.body))
		req.Header.Set("Authorization", "Bearer supersecret")
		req.Header.Set("X-Request-ID", "untrusted")
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, req)
		if response.Code != tc.status {
			t.Fatalf("%s: %d %s", tc.path, response.Code, response.Body)
		}
		id := response.Header().Get("X-Request-ID")
		if id == "" || id == "untrusted" || seen[id] {
			t.Fatal("request ID not fresh")
		}
		seen[id] = true
		if tc.code != "" {
			var out ErrorEnvelope
			if err := json.Unmarshal(response.Body.Bytes(), &out); err != nil {
				t.Fatal(err)
			}
			if out.Error.Code != tc.code || out.RequestID != id || out.Error.Fields == nil {
				t.Fatalf("invalid envelope: %+v", out)
			}
		}
	}
	if strings.Contains(logs.String(), "supersecret") || strings.Contains(logs.String(), "secret@example.com") {
		t.Fatal("sensitive log")
	}
	if strings.Count(logs.String(), "http_request_completed") != len(cases) {
		t.Fatal("one log per request required")
	}
}

func TestPanicAndUnavailable(t *testing.T) {
	for _, panicMode := range []bool{false, true} {
		var logs bytes.Buffer
		h := New(logging.New(&logs, "test", "test"), func(context.Context) error {
			if panicMode {
				panic("database password secret")
			}
			return fmt.Errorf("database password secret")
		}, false)
		response := httptest.NewRecorder()
		h.ServeHTTP(response, httptest.NewRequest("GET", "/health/ready", nil))
		expected := 503
		if panicMode {
			expected = 500
		}
		if response.Code != expected {
			t.Fatal(response.Code)
		}
		if strings.Contains(response.Body.String()+logs.String(), "password") {
			t.Fatal("raw error exposed")
		}
	}
}

func TestDiagnosticsDisabled(t *testing.T) {
	h := New(logging.New(&bytes.Buffer{}, "production", "test"), nil, false)
	r := httptest.NewRecorder()
	h.ServeHTTP(r, httptest.NewRequest("POST", "/dev/validate", strings.NewReader(`{"quantity":1}`)))
	if r.Code != 404 {
		t.Fatal(r.Code)
	}
}
