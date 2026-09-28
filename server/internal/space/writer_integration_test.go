//go:build integration

package space

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
	"way2we/server/internal/platform/testdb"

	"github.com/jackc/pgx/v5"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

func TestCommandAtomicityReplayAndAuthorization(t *testing.T) {
	pool := testdb.New(t)
	ctx := context.Background()
	actor, space, member := identifier.New(), identifier.New(), identifier.New()
	for _, step := range []struct {
		sql  string
		args []any
	}{
		{"INSERT INTO users(id,display_name) VALUES($1,'测试')", []any{actor}},
		{"INSERT INTO spaces(id,name,created_by) VALUES($1,'测试空间',$2)", []any{space, actor}},
		{"INSERT INTO memberships(id,space_id,user_id,nickname) VALUES($1,$2,$3,'测试')", []any{member, space, actor}},
	} {
		if _, err := pool.Exec(ctx, step.sql, step.args...); err != nil {
			t.Fatal(err)
		}
	}
	authorize := func(ctx context.Context, tx pgx.Tx) error {
		var status string
		err := tx.QueryRow(ctx, "SELECT status FROM memberships WHERE space_id=$1 AND user_id=$2", space, actor).Scan(&status)
		if err != nil {
			return err
		}
		if status != "active" {
			return apperror.New("MEMBERSHIP_INACTIVE")
		}
		return nil
	}
	var calls atomic.Int32
	apply := func(ctx context.Context, tx pgx.Tx) (Result, error) {
		calls.Add(1)
		var n int64
		err := tx.QueryRow(ctx, "UPDATE memberships SET balance=balance+10 WHERE id=$1 RETURNING balance", member).Scan(&n)
		body, _ := json.Marshal(map[string]int64{"balance": n})
		return Result{Status: 200, Body: body}, err
	}
	writer := NewWriter(pool)
	command := Command{ActorID: actor, Key: identifier.New(), Operation: "testScore", SpaceID: space, Parameters: json.RawMessage(`{"points":10}`)}
	var wg sync.WaitGroup
	errs := make(chan error, 12)
	for range 12 {
		wg.Go(func() {
			out, err := writer.Run(ctx, command, authorize, apply)
			if err == nil && !strings.Contains(string(out.Body), "10") {
				err = fmt.Errorf("wrong replay body")
			}
			errs <- err
		})
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if calls.Load() != 1 {
		t.Fatalf("applied %d times", calls.Load())
	}
	// A new service instance uses the persisted result without applying again.
	if out, err := NewWriter(pool).Run(ctx, command, authorize, apply); err != nil || !out.Replayed {
		t.Fatalf("restart replay: %+v %v", out, err)
	}
	changed := command
	changed.Parameters = json.RawMessage(`{"points":20}`)
	if _, err := writer.Run(ctx, changed, authorize, apply); businessCode(err) != "IDEMPOTENCY_KEY_REUSED" {
		t.Fatalf("changed parameters: %v", err)
	}
	failed := command
	failed.Key = identifier.New()
	_, err := writer.Run(ctx, failed, authorize, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		if _, err := apply(ctx, tx); err != nil {
			return Result{}, err
		}
		return Result{}, fmt.Errorf("injected failure after business write")
	})
	if err == nil {
		t.Fatal("failure expected")
	}
	var balance int64
	var count int
	if err = pool.QueryRow(ctx, "SELECT balance FROM memberships WHERE id=$1", member).Scan(&balance); err != nil {
		t.Fatal(err)
	}
	if err = pool.QueryRow(ctx, "SELECT count(*) FROM commands").Scan(&count); err != nil {
		t.Fatal(err)
	}
	if balance != 10 || count != 1 {
		t.Fatalf("rollback failed: balance=%d commands=%d", balance, count)
	}
	if _, err = pool.Exec(ctx, "UPDATE memberships SET status='left',left_at=now() WHERE id=$1", member); err != nil {
		t.Fatal(err)
	}
	if _, err = writer.Run(ctx, command, authorize, apply); businessCode(err) != "MEMBERSHIP_INACTIVE" {
		t.Fatalf("replay bypassed permission: %v", err)
	}
}

func businessCode(err error) string {
	var e *apperror.Error
	if errors.As(err, &e) {
		return e.Code
	}
	return ""
}

func TestCancelledTransactionLeavesNoWrites(t *testing.T) {
	pool := testdb.New(t)
	ctx, cancel := context.WithTimeout(context.Background(), time.Nanosecond)
	defer cancel()
	c := Command{ActorID: identifier.New(), Key: identifier.New(), Operation: "test", SpaceID: identifier.New(), Parameters: json.RawMessage(`{}`)}
	_, err := NewWriter(pool).Run(ctx, c, func(context.Context, pgx.Tx) error { return nil }, func(context.Context, pgx.Tx) (Result, error) {
		t.Error("cancelled operation executed")
		return Result{}, nil
	})
	if err == nil {
		t.Fatal("cancellation expected")
	}
}
