//go:build integration

package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http/httptest"
	"strings"
	"testing"

	"way2we/server/internal/account"
	"way2we/server/internal/platform/logging"
	"way2we/server/internal/platform/testdb"
)

type captureMail struct{ message account.CodeMail }

func (m *captureMail) SendCode(_ context.Context, value account.CodeMail) error {
	m.message = value
	return nil
}
func TestAccountHTTPAndLogPrivacy(t *testing.T) {
	pool := testdb.New(t)
	sender := &captureMail{}
	service, err := account.New(pool, bytes.Repeat([]byte{1}, 32), sender)
	if err != nil {
		t.Fatal(err)
	}
	var logs bytes.Buffer
	handler := New(logging.New(&logs, "test", "test"), pool.Ping, false, service)
	call := func(method, path, body, token string, status int) *httptest.ResponseRecorder {
		t.Helper()
		req := httptest.NewRequest(method, path, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, req)
		if w.Code != status {
			t.Fatalf("%s %s returned %d", method, path, w.Code)
		}
		return w
	}
	call("POST", "/v1/auth/email-codes", `{"email":"private@example.test"}`, "", 202)
	if _, err = service.DeliverOne(t.Context()); err != nil {
		t.Fatal(err)
	}
	request, _ := json.Marshal(map[string]string{"email": sender.message.Email, "code": sender.message.Code})
	response := call("POST", "/v1/auth/sessions", string(request), "", 201)
	var result account.Session
	if err = json.Unmarshal(response.Body.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	call("GET", "/v1/me", "", result.AccessToken, 200)
	for _, body := range []string{`null`, `{"theme":null}`, `{"unknown":true}`, `{} {}`, strings.Repeat("x", 17000)} {
		call("PATCH", "/v1/me", body, result.AccessToken, 400)
	}
	logout := call("DELETE", "/v1/auth/session", "", result.AccessToken, 204)
	if logout.Body.Len() != 0 {
		t.Fatal("204 body must be empty")
	}
	call("GET", "/v1/me", "", result.AccessToken, 401)
	for _, secret := range []string{sender.message.Email, sender.message.Code, result.AccessToken, "Authorization"} {
		if strings.Contains(logs.String(), secret) {
			t.Fatal("sensitive authentication data leaked to log")
		}
	}
	if !strings.Contains(logs.String(), `"actor_id"`) {
		t.Fatal("verified identity missing from audit logs")
	}
}
