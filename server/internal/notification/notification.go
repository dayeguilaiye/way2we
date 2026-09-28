// Package notification records durable events and projects them to inbox entries.
package notification

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"time"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
	"way2we/server/internal/platform/paging"
)

type Resource struct {
	Kind    string `json:"kind"`
	ID      string `json:"id"`
	SpaceID string `json:"space_id"`
}
type Event struct {
	ID, SpaceID, ActorID, Type, Summary, RequestID string
	Recipients                                     []string
	Resource                                       Resource
}
type Notification struct {
	ID        string     `json:"id"`
	Type      string     `json:"event_type"`
	Resource  Resource   `json:"resource"`
	Summary   string     `json:"summary"`
	CreatedAt time.Time  `json:"created_at"`
	ReadAt    *time.Time `json:"read_at"`
}

// Record belongs to the caller's business transaction. Payloads contain no credentials.
func Record(ctx context.Context, tx pgx.Tx, event Event) error {
	resource, e := json.Marshal(event.Resource)
	if e != nil {
		return e
	}
	payload, e := json.Marshal(map[string]string{"summary": event.Summary})
	if e != nil {
		return e
	}
	_, e = tx.Exec(ctx, `INSERT INTO notification_events(id,space_id,event_type,actor_user_id,recipient_ids,resource_ref,payload,request_id) VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, identifier.New(), event.SpaceID, event.Type, event.ActorID, event.Recipients, resource, payload, event.RequestID)
	return e
}

// Channel records channel-specific delivery jobs in the same projection transaction.
// Senders consume those jobs outside the transaction, with their own delivery state.
// In-app projection and business modules do not depend on an external channel.
type Channel interface {
	Enqueue(context.Context, pgx.Tx, Event) error
}
type Worker struct {
	Pool     *pgxpool.Pool
	Channels []Channel
}

func (w *Worker) Process(ctx context.Context) (bool, error) {
	owner := identifier.New()
	var event Event
	var resource, payload []byte
	var attempt int
	err := w.Pool.QueryRow(ctx, `UPDATE notification_events SET status='processing',lease_owner=$1,lease_until=clock_timestamp()+interval '30 seconds',attempts=attempts+1 WHERE id=(SELECT id FROM notification_events WHERE (status='pending' AND available_at<=clock_timestamp()) OR (status='processing' AND lease_until<clock_timestamp()) ORDER BY available_at,id FOR UPDATE SKIP LOCKED LIMIT 1) RETURNING id,space_id,event_type,actor_user_id,recipient_ids,resource_ref,payload,request_id,attempts`, owner).Scan(&event.ID, &event.SpaceID, &event.Type, &event.ActorID, &event.Recipients, &resource, &payload, &event.RequestID, &attempt)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	err = w.project(ctx, owner, &event, resource, payload)
	if err != nil {
		cleanup, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		_, resetErr := w.Pool.Exec(cleanup, `UPDATE notification_events SET status=CASE WHEN attempts>=8 THEN 'failed' ELSE 'pending' END,available_at=clock_timestamp()+interval '10 seconds',lease_until=NULL,lease_owner=NULL WHERE id=$1 AND lease_owner=$2`, event.ID, owner)
		if resetErr != nil {
			return true, &jobError{event.ID, event.RequestID, attempt, errors.Join(err, resetErr)}
		}
	}
	if err != nil {
		return true, &jobError{event.ID, event.RequestID, attempt, err}
	}
	return true, nil
}
func (w *Worker) project(ctx context.Context, owner string, event *Event, resource, payload []byte) error {
	tx, err := w.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(context.WithoutCancel(ctx))
	var id string
	err = tx.QueryRow(ctx, "SELECT id FROM notification_events WHERE id=$1 AND lease_owner=$2 AND status='processing' FOR UPDATE", event.ID, owner).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}
	var data struct {
		Summary string `json:"summary"`
	}
	if err = json.Unmarshal(payload, &data); err != nil {
		return err
	}
	if err = json.Unmarshal(resource, &event.Resource); err != nil {
		return err
	}
	event.Summary = data.Summary
	for _, uid := range event.Recipients {
		_, err = tx.Exec(ctx, `INSERT INTO notifications(id,event_id,recipient_user_id,space_id,event_type,resource_ref,summary) VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT(event_id,recipient_user_id) DO NOTHING`, identifier.New(), event.ID, uid, event.SpaceID, event.Type, resource, event.Summary)
		if err != nil {
			return err
		}
	}
	for _, channel := range w.Channels {
		if err = channel.Enqueue(ctx, tx, *event); err != nil {
			return err
		}
	}
	if _, err = tx.Exec(ctx, "UPDATE notification_events SET status='done',lease_owner=NULL,lease_until=NULL WHERE id=$1", event.ID); err != nil {
		return err
	}
	return tx.Commit(ctx)
}
func (w *Worker) Run(ctx context.Context, logger *slog.Logger) {
	timer := time.NewTicker(time.Second)
	defer timer.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
			for range 20 {
				start := time.Now()
				jobCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
				worked, err := w.Process(jobCtx)
				cancel()
				if err != nil {
					attrs := []any{"event", "notification_job_failed", "error_kind", "projection", "duration_ms", time.Since(start).Milliseconds()}
					var job *jobError
					level := slog.LevelWarn
					if errors.As(err, &job) {
						attrs = append(attrs, "event_id", job.id, "job_id", job.id, "origin_request_id", job.request, "attempt", job.attempt)
						if job.attempt >= 8 {
							level = slog.LevelError
						}
					}
					logger.Log(ctx, level, "notification projection failed", attrs...)
					break
				}
				if !worked {
					break
				}
			}
		}
	}
}

// Visibility is checked at read time, including when following an old notification.
const visible = `(EXISTS(SELECT 1 FROM memberships m WHERE m.space_id=n.space_id AND m.user_id=$1 AND m.status='active') OR (n.resource_ref->>'kind'='invitation' AND EXISTS(SELECT 1 FROM invitations i WHERE i.id::text=n.resource_ref->>'id' AND i.candidate_user_id=$1 AND i.status='waiting')))`
const columns = `n.id,n.event_type,n.resource_ref,n.summary,n.created_at,n.read_at`

func scan(row pgx.Row) (v Notification, err error) {
	var raw []byte
	err = row.Scan(&v.ID, &v.Type, &raw, &v.Summary, &v.CreatedAt, &v.ReadAt)
	if err != nil {
		return v, err
	}
	err = json.Unmarshal(raw, &v.Resource)
	return
}
func Read(ctx context.Context, tx pgx.Tx, uid, id string) (Notification, error) {
	v, e := scan(tx.QueryRow(ctx, "SELECT "+columns+" FROM notifications n WHERE n.recipient_user_id=$1 AND n.id=$2 AND "+visible, uid, id))
	if errors.Is(e, pgx.ErrNoRows) {
		return v, apperror.New("NOT_FOUND")
	}
	return v, e
}
func List(ctx context.Context, tx pgx.Tx, uid string, q paging.Query, unread bool) (out paging.Page[Notification], err error) {
	out.Items = []Notification{}
	scope := "notifications:" + uid
	if unread {
		scope += ":unread"
	}
	pos, err := q.Decode(scope)
	if err != nil {
		return out, err
	}
	rows, err := tx.Query(ctx, "SELECT "+columns+" FROM notifications n WHERE n.recipient_user_id=$1 AND "+visible+" AND (NOT $2 OR n.read_at IS NULL) AND (n.created_at,n.id)<($3,$4) ORDER BY n.created_at DESC,n.id DESC LIMIT $5", uid, unread, pos.Time, pos.ID, q.Limit+1)
	if err != nil {
		return out, err
	}
	defer rows.Close()
	for rows.Next() {
		v, e := scan(rows)
		if e != nil {
			return out, e
		}
		out.Items = append(out.Items, v)
	}
	if err = rows.Err(); err != nil {
		return out, err
	}
	if len(out.Items) > q.Limit {
		out.Items = out.Items[:q.Limit]
		v := out.Items[len(out.Items)-1]
		out.Next = paging.Next(scope, v.CreatedAt, v.ID)
	}
	return
}

type jobError struct {
	id, request string
	attempt     int
	cause       error
}

func (e *jobError) Error() string { return "notification projection failed" }
func (e *jobError) Unwrap() error { return e.cause }
