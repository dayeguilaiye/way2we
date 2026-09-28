// Package paging provides scope-bound keyset cursors for public lists.
package paging

import (
	"encoding/base64"
	"encoding/json"
	"net/url"
	"strconv"
	"time"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

type Query struct {
	Limit  int
	Cursor string
}
type Position struct {
	Scope string
	Time  time.Time
	ID    string
}
type Page[T any] struct {
	Items []T     `json:"items"`
	Next  *string `json:"next_cursor"`
}

func Parse(v url.Values) (Query, error) {
	q := Query{Limit: 20, Cursor: v.Get("cursor")}
	if raw := v.Get("limit"); raw != "" {
		n, e := strconv.Atoi(raw)
		if e != nil || n < 1 || n > 100 {
			return q, apperror.New("INVALID_REQUEST")
		}
		q.Limit = n
	}
	return q, nil
}
func (q Query) Decode(scope string) (Position, error) {
	p := Position{Scope: scope, Time: time.Date(9999, 1, 1, 0, 0, 0, 0, time.UTC), ID: "ffffffff-ffff-ffff-ffff-ffffffffffff"}
	if q.Limit < 1 || q.Limit > 100 {
		return p, apperror.New("INVALID_REQUEST")
	}
	if q.Cursor == "" {
		return p, nil
	}
	b, err := base64.RawURLEncoding.DecodeString(q.Cursor)
	if err != nil || json.Unmarshal(b, &p) != nil || p.Scope != scope || !identifier.Valid(p.ID) || p.Time.IsZero() {
		return p, apperror.New("INVALID_REQUEST")
	}
	return p, nil
}
func Next(scope string, t time.Time, id string) *string {
	b, _ := json.Marshal(Position{scope, t, id})
	s := base64.RawURLEncoding.EncodeToString(b)
	return &s
}
