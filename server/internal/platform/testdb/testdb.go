//go:build integration

// Package testdb creates isolated schemas in the dedicated local test database.
package testdb

import (
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/url"
	"os"
	"strings"
	"testing"
	"way2we/server/internal/platform/database"
	"way2we/server/internal/platform/identifier"
	"way2we/server/migrations"
)

func New(t *testing.T) *pgxpool.Pool {
	t.Helper()
	raw := os.Getenv("TEST_DATABASE_URL")
	u, err := url.Parse(raw)
	if err != nil || u == nil || u.Path != "/way2we_test" || (u.Hostname() != "127.0.0.1" && u.Hostname() != "localhost") || u.Port() != "55433" {
		t.Fatal("integration tests require the dedicated local way2we_test database on port 55433")
	}
	ctx := context.Background()
	admin, err := database.Open(ctx, raw)
	if err != nil {
		t.Fatal("test database unavailable")
	}
	schema := "test_" + strings.ReplaceAll(identifier.New(), "-", "")
	_, err = admin.Exec(ctx, "CREATE SCHEMA "+pgx.Identifier{schema}.Sanitize())
	if err != nil {
		admin.Close()
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, err := admin.Exec(context.Background(), "DROP SCHEMA "+pgx.Identifier{schema}.Sanitize()+" CASCADE")
		if err != nil {
			t.Error(err)
		}
		admin.Close()
	})
	q := u.Query()
	q.Set("search_path", schema)
	u.RawQuery = q.Encode()
	for range 2 {
		if err = migrations.Up(ctx, u.String()); err != nil {
			t.Fatal(err)
		}
	}
	pool, err := database.Open(ctx, u.String())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}
