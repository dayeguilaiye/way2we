package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/paging"
	"way2we/server/internal/space"
)

// Match templates before authentication so logs never contain invitation codes or IDs.
func spaceRoute(r *http.Request) string {
	p := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	if len(p) < 2 || p[0] != "v1" {
		return ""
	}
	switch {
	case len(p) == 2 && p[1] == "spaces" && (r.Method == "GET" || r.Method == "POST"):
		return "/v1/spaces"
	case len(p) == 3 && p[1] == "spaces" && r.Method == "GET":
		return "/v1/spaces/{space_id}"
	case len(p) == 4 && p[1] == "spaces" && p[3] == "members" && r.Method == "GET":
		return "/v1/spaces/{space_id}/members"
	case len(p) == 5 && p[1] == "spaces" && p[3] == "members" && p[4] == "me" && r.Method == "PATCH":
		return "/v1/spaces/{space_id}/members/me"
	case len(p) == 4 && p[1] == "spaces" && p[3] == "invitations" && (r.Method == "GET" || r.Method == "POST"):
		return "/v1/spaces/{space_id}/invitations"
	case len(p) == 6 && p[1] == "spaces" && p[3] == "invitations" && p[5] == "approve" && r.Method == "POST":
		return "/v1/spaces/{space_id}/invitations/{invitation_id}/approve"
	case len(p) == 3 && p[1] == "invitations" && (p[2] == "preview" || p[2] == "accept") && r.Method == "POST":
		return "/v1/invitations/" + p[2]
	case len(p) == 3 && p[1] == "invitations" && r.Method == "GET":
		return "/v1/invitations/{invitation_id}"
	case len(p) == 2 && p[1] == "notifications" && r.Method == "GET":
		return "/v1/notifications"
	case len(p) == 4 && p[1] == "notifications" && p[3] == "read" && r.Method == "PUT":
		return "/v1/notifications/{notification_id}/read"
	}
	return ""
}
func (h *Handler) spaceRequest(ctx context.Context, w http.ResponseWriter, r *http.Request, rid, route string) (status int, body any, actor string, err error) {
	parts := strings.Fields(r.Header.Get("Authorization"))
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return 0, nil, "", apperror.New("UNAUTHENTICATED")
	}
	p, e := h.accounts.Authenticate(ctx, parts[1])
	if e != nil {
		return 0, nil, "", e
	}
	actor = p.UserID
	status = 200
	paths := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
	key := r.Header.Get("Idempotency-Key")
	q, e := paging.Parse(r.URL.Query())
	if e != nil {
		return 0, nil, actor, e
	}
	var command space.Result
	switch route {
	case "/v1/spaces":
		if r.Method == "GET" {
			body, err = h.spaces.List(ctx, p, q)
		} else {
			var in space.CreateInput
			if err = decodeObject(w, r, &in); err == nil {
				command, err = h.spaces.Create(ctx, p, key, rid, in)
			}
		}
	case "/v1/spaces/{space_id}":
		body, err = h.spaces.Get(ctx, p, paths[2])
	case "/v1/spaces/{space_id}/members":
		body, err = h.spaces.Members(ctx, p, paths[2], q)
	case "/v1/spaces/{space_id}/members/me":
		var in struct {
			Nickname string `json:"nickname"`
		}
		if err = decodeObject(w, r, &in); err == nil {
			command, err = h.spaces.Nickname(ctx, p, key, paths[2], in.Nickname, rid)
		}
	case "/v1/spaces/{space_id}/invitations":
		if r.Method == "GET" {
			body, err = h.spaces.Invitations(ctx, p, paths[2], q)
		} else {
			status = 201
			body, err = h.spaces.CreateInvitation(ctx, p, key, paths[2], rid)
		}
	case "/v1/invitations/preview":
		var in struct {
			Code string `json:"invite_code"`
		}
		if err = decodeObject(w, r, &in); err == nil {
			body, err = h.spaces.Preview(ctx, p, in.Code)
		}
	case "/v1/invitations/accept":
		var in space.AcceptInput
		if err = decodeObject(w, r, &in); err == nil {
			command, err = h.spaces.Accept(ctx, p, key, rid, in)
		}
	case "/v1/invitations/{invitation_id}":
		body, err = h.spaces.Invitation(ctx, p, paths[2])
	case "/v1/spaces/{space_id}/invitations/{invitation_id}/approve":
		command, err = h.spaces.Approve(ctx, p, key, paths[2], paths[4], rid)
	case "/v1/notifications":
		raw := r.URL.Query().Get("unread_only")
		if raw != "" && raw != "true" && raw != "false" {
			err = apperror.New("INVALID_REQUEST")
		} else {
			body, err = h.spaces.Notifications(ctx, p, q, raw == "true")
		}
	case "/v1/notifications/{notification_id}/read":
		command, err = h.spaces.ReadNotification(ctx, p, key, paths[2])
	}
	if command.Status != 0 {
		status = command.Status
		body = json.RawMessage(command.Body)
	}
	return
}
