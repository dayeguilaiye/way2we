package httpapi

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime"
	"net"
	"net/http"
	"strings"

	"way2we/server/internal/account"
	"way2we/server/internal/platform/apperror"
)

func isAccountRoute(r *http.Request) bool {
	switch r.URL.Path {
	case "/v1/auth/email-codes", "/v1/auth/sessions":
		return r.Method == http.MethodPost
	case "/v1/auth/session":
		return r.Method == http.MethodDelete
	case "/v1/me":
		return r.Method == http.MethodGet || r.Method == http.MethodPatch
	}
	return false
}

// Decode a bounded JSON object, rejecting unknown fields, null values and trailing data.
func decodeObject(w http.ResponseWriter, r *http.Request, out any) error {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		return apperror.New("INVALID_REQUEST")
	}
	raw, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 16384))
	if err != nil {
		return apperror.New("INVALID_REQUEST")
	}
	var fields map[string]json.RawMessage
	if json.Unmarshal(raw, &fields) != nil || fields == nil {
		return apperror.New("INVALID_REQUEST")
	}
	for _, v := range fields {
		if bytes.Equal(bytes.TrimSpace(v), []byte("null")) {
			return apperror.New("INVALID_REQUEST")
		}
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if decoder.Decode(out) != nil {
		return apperror.New("INVALID_REQUEST")
	}
	return nil
}

func (h *Handler) accountRequest(ctx context.Context, w http.ResponseWriter, r *http.Request, requestID string) (int, any, string, error) {
	// Only the socket peer is trusted until deployment configures a trusted proxy.
	source, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		source = r.RemoteAddr
	}
	if r.URL.Path == "/v1/auth/email-codes" {
		var input struct {
			Email string `json:"email"`
		}
		if err = decodeObject(w, r, &input); err != nil {
			return 0, nil, "", err
		}
		result, err := h.accounts.RequestCode(ctx, input.Email, source, requestID)
		return 202, result, "", err
	}
	if r.URL.Path == "/v1/auth/sessions" {
		var input struct {
			Email string `json:"email"`
			Code  string `json:"code"`
		}
		if err = decodeObject(w, r, &input); err != nil {
			return 0, nil, "", err
		}
		result, err := h.accounts.Login(ctx, input.Email, input.Code, source)
		return 201, result, result.User.ID, err
	}
	parts := strings.Fields(r.Header.Get("Authorization"))
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return 0, nil, "", apperror.New("UNAUTHENTICATED")
	}
	principal, err := h.accounts.Authenticate(ctx, parts[1])
	if err != nil {
		return 0, nil, "", err
	}
	if r.Method == http.MethodDelete {
		return 204, nil, principal.UserID, h.accounts.Logout(ctx, principal)
	}
	if r.Method == http.MethodGet {
		result, err := h.accounts.Me(ctx, principal)
		return 200, result, principal.UserID, err
	}
	var change account.ProfileUpdate
	if err = decodeObject(w, r, &change); err != nil {
		return 0, nil, principal.UserID, err
	}
	result, err := h.accounts.Update(ctx, principal, r.Header.Get("Idempotency-Key"), change)
	return 200, result, principal.UserID, err
}
