package space

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

type Command struct {
	ActorID, Key, Operation, SpaceID string
	Parameters                       json.RawMessage
}
type Result struct {
	Status   int
	Body     json.RawMessage
	Replayed bool
}
type Writer struct{ pool *pgxpool.Pool }

func NewWriter(pool *pgxpool.Pool) *Writer { return &Writer{pool: pool} }

// Run serializes a space write and commits its result atomically. ActorID must
// come from authenticated identity. Parameters must be normalized typed JSON,
// including target IDs. authorize runs on EVERY attempt, including replay.
// apply must use tx for all writes, perform no external calls, and return only
// safe public JSON. Any apply error rolls back all writes and the command.
// Sensitive invitation results require an encrypted codec before using Run.
func (w *Writer) Run(ctx context.Context, c Command, authorize func(context.Context, pgx.Tx) error, apply func(context.Context, pgx.Tx) (Result, error)) (out Result, err error) {
	if !identifier.Valid(c.ActorID) || !identifier.Valid(c.Key) || !identifier.Valid(c.SpaceID) || c.Operation == "" || !json.Valid(c.Parameters) || authorize == nil || apply == nil {
		return out, apperror.New("INVALID_REQUEST")
	}
	normalized, err := json.Marshal(struct {
		Operation, Space string
		Params           json.RawMessage
	}{c.Operation, c.SpaceID, c.Parameters})
	if err != nil {
		return out, fmt.Errorf("encode command: %w", err)
	}
	fingerprint := sha256.Sum256(normalized)
	tx, err := w.pool.Begin(ctx)
	if err != nil {
		return out, fmt.Errorf("begin space command: %w", err)
	}
	defer func() {
		cleanup, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		_ = tx.Rollback(cleanup)
	}()
	defer func() {
		var pgerr *pgconn.PgError
		if errors.As(err, &pgerr) && pgerr.Code == "55P03" {
			err = apperror.New("OPERATION_IN_PROGRESS")
		}
	}()
	var id string
	err = tx.QueryRow(ctx, "SELECT id FROM spaces WHERE id=$1 FOR UPDATE", c.SpaceID).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return out, apperror.New("NOT_FOUND")
	}
	if err != nil {
		return out, fmt.Errorf("lock space: %w", err)
	}
	if err = authorize(ctx, tx); err != nil {
		return out, err
	}
	// A key is unique per account across spaces. The transaction advisory lock
	// prevents cross-space reuse executing business writes before detecting it.
	lockHash := sha256.Sum256([]byte(c.ActorID + ":" + c.Key))
	if _, err = tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", int64(binary.BigEndian.Uint64(lockHash[:8]))); err != nil {
		return out, fmt.Errorf("lock command: %w", err)
	}
	var storedHash []byte
	err = tx.QueryRow(ctx, "SELECT request_hash,http_status,response_body FROM commands WHERE actor_user_id=$1 AND idempotency_key=$2", c.ActorID, c.Key).Scan(&storedHash, &out.Status, &out.Body)
	if err == nil {
		if !bytes.Equal(storedHash, fingerprint[:]) {
			return Result{}, apperror.New("IDEMPOTENCY_KEY_REUSED")
		}
		out.Replayed = true
		return out, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return out, fmt.Errorf("read command: %w", err)
	}
	out, err = apply(ctx, tx)
	if err != nil {
		return Result{}, err
	}
	if out.Status < 200 || out.Status >= 300 || !json.Valid(out.Body) {
		return Result{}, fmt.Errorf("command produced invalid success result")
	}
	_, err = tx.Exec(ctx, `INSERT INTO commands(actor_user_id,idempotency_key,operation_name,space_id,request_hash,result_status,http_status,response_body) VALUES($1,$2,$3,$4,$5,'succeeded',$6,$7)`, c.ActorID, c.Key, c.Operation, c.SpaceID, fingerprint[:], out.Status, out.Body)
	if err != nil {
		return Result{}, fmt.Errorf("store command: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return Result{}, fmt.Errorf("commit command: %w", err)
	}
	return out, nil
}
