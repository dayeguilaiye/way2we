package httpapi

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"way2we/server/internal/account"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
	"way2we/server/internal/space"
)

type Handler struct {
	logger      *slog.Logger
	ping        func(context.Context) error
	diagnostics bool
	accounts    *account.Service
	spaces      *space.Service
}

func New(logger *slog.Logger, ping func(context.Context) error, diagnostics bool, accounts *account.Service, spaces ...*space.Service) http.Handler {
	h := &Handler{logger: logger, ping: ping, diagnostics: diagnostics, accounts: accounts}
	if len(spaces) > 0 {
		h.spaces = spaces[0]
	}
	return h
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	requestID := identifier.New()
	w.Header().Set("X-Request-ID", requestID)
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	route := "unmatched"
	status := 200
	var body any
	var err error
	actorID := ""
	defer func() {
		if recover() != nil {
			err = fmt.Errorf("handler panic")
		}
		var envelope ErrorEnvelope
		if err != nil {
			status, envelope = mapError(err, requestID)
			body = envelope
		}
		encoded, encodeErr := json.Marshal(body)
		if encodeErr != nil {
			err = encodeErr
			status, envelope = mapError(err, requestID)
			encoded, _ = json.Marshal(envelope)
		}
		if status == 429 {
			w.Header().Set("Retry-After", "60")
		}
		var writeErr error
		if status == http.StatusNoContent {
			w.Header().Del("Content-Type")
			w.WriteHeader(status)
		} else {
			w.WriteHeader(status)
			_, writeErr = w.Write(append(encoded, '\n'))
		}
		attrs := []any{"event", "http_request_completed", "request_id", requestID, "method", r.Method, "route", route, "http_status", status, "duration_ms", time.Since(start).Milliseconds()}
		if actorID != "" {
			attrs = append(attrs, "actor_id", actorID)
		}
		level := slog.LevelInfo
		if err != nil {
			attrs = append(attrs, "error_code", envelope.Error.Code, "error_kind", safeErrorKind(err))
			if status >= 500 {
				level = slog.LevelError
			}
			if status == 503 {
				level = slog.LevelWarn
			}
		}
		if writeErr != nil {
			attrs = append(attrs, "delivery", "failed")
		}
		h.logger.Log(r.Context(), level, "request completed", attrs...)
	}()
	ctx, cancel := context.WithTimeout(r.Context(), 12*time.Second)
	defer cancel()
	switch {
	case r.Method == http.MethodGet && r.URL.Path == "/health/live":
		route = "/health/live"
		body = map[string]string{"status": "ok"}
	case r.Method == http.MethodGet && r.URL.Path == "/health/ready":
		route = "/health/ready"
		readyCtx, readyCancel := context.WithTimeout(ctx, 2*time.Second)
		defer readyCancel()
		if h.ping(readyCtx) != nil {
			err = apperror.New("SERVICE_UNAVAILABLE")
			return
		}
		body = map[string]string{"status": "ok"}
	case h.diagnostics && r.Method == http.MethodPost && r.URL.Path == "/dev/validate":
		route = "/dev/validate"
		var input struct {
			Quantity int64 `json:"quantity"`
		}
		decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1024))
		decoder.DisallowUnknownFields()
		if decoder.Decode(&input) != nil {
			err = apperror.New("INVALID_REQUEST")
			return
		}
		var extra any
		if decoder.Decode(&extra) != io.EOF {
			err = apperror.New("INVALID_REQUEST")
			return
		}
		if input.Quantity <= 0 {
			err = &apperror.Error{Code: "VALIDATION_FAILED", Fields: []apperror.Field{{Field: "quantity", Code: "POSITIVE_INTEGER_REQUIRED"}}}
			return
		}
		body = map[string]int64{"quantity": input.Quantity}
	case h.accounts != nil && isAccountRoute(r):
		route = r.URL.Path
		status, body, actorID, err = h.accountRequest(ctx, w, r, requestID)
	case h.spaces != nil && spaceRoute(r) != "":
		route = spaceRoute(r)
		status, body, actorID, err = h.spaceRequest(ctx, w, r, requestID, route)
	default:
		err = apperror.New("NOT_FOUND")
	}
}
