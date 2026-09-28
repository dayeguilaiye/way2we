//go:build integration

package space

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"sync"
	"testing"
	"way2we/server/internal/account"
	"way2we/server/internal/notification"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
	"way2we/server/internal/platform/paging"
	"way2we/server/internal/platform/testdb"
)

func person(t *testing.T, pool *pgxpool.Pool, name string) account.Principal {
	t.Helper()
	p := account.Principal{UserID: identifier.New(), SessionID: identifier.New()}
	sum := sha256.Sum256([]byte(p.SessionID))
	_, e := pool.Exec(context.Background(), "INSERT INTO users(id,display_name) VALUES($1,$2)", p.UserID, name)
	if e != nil {
		t.Fatal(e)
	}
	_, e = pool.Exec(context.Background(), "INSERT INTO sessions(id,user_id,token_hash,created_at,expires_at) VALUES($1,$2,$3,now(),now()+interval '1 day')", p.SessionID, p.UserID, sum[:])
	if e != nil {
		t.Fatal(e)
	}
	return p
}
func made(t *testing.T, s *Service, p account.Principal, name string) Created {
	t.Helper()
	r, e := s.Create(context.Background(), p, identifier.New(), identifier.New(), CreateInput{name, name})
	if e != nil {
		t.Fatal(e)
	}
	var v Created
	if e = json.Unmarshal(r.Body, &v); e != nil {
		t.Fatal(e)
	}
	return v
}
func invite(t *testing.T, s *Service, p account.Principal, sid string) InvitationCreated {
	t.Helper()
	v, e := s.CreateInvitation(context.Background(), p, identifier.New(), sid, identifier.New())
	if e != nil {
		t.Fatal(e)
	}
	return v
}
func accept(t *testing.T, s *Service, p account.Principal, code, name string) Invitation {
	t.Helper()
	r, e := s.Accept(context.Background(), p, identifier.New(), identifier.New(), AcceptInput{code, name})
	if e != nil {
		t.Fatal(e)
	}
	var v Invitation
	if e = json.Unmarshal(r.Body, &v); e != nil {
		t.Fatal(e)
	}
	return v
}
func errorCode(t *testing.T, e error, code string) {
	t.Helper()
	var b *apperror.Error
	if !errors.As(e, &b) || b.Code != code {
		t.Fatalf("want %s, got %v", code, e)
	}
}
func TestSpaceInvitationsAndNotifications(t *testing.T) {
	pool := testdb.New(t)
	s, e := New(pool, make([]byte, 32))
	if e != nil {
		t.Fatal(e)
	}
	ctx := context.Background()
	a := person(t, pool, "甲")
	b := person(t, pool, "乙")
	c := person(t, pool, "丙")
	other := person(t, pool, "旁人")
	// Concurrent creation with one intent creates one space and member.
	key := identifier.New()
	var wg sync.WaitGroup
	results := make(chan Result, 6)
	errs := make(chan error, 6)
	for range 6 {
		wg.Go(func() {
			r, e := s.Create(ctx, a, key, identifier.New(), CreateInput{"共同空间", "阿禾"})
			results <- r
			errs <- e
		})
	}
	wg.Wait()
	close(results)
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	var initial Created
	for r := range results {
		var v Created
		_ = json.Unmarshal(r.Body, &v)
		if initial.Space.ID != "" && initial.Space.ID != v.Space.ID {
			t.Fatal("duplicate creation")
		}
		initial = v
	}
	sid := initial.Space.ID
	_, e = s.Create(ctx, a, key, identifier.New(), CreateInput{"另一名称", "阿禾"})
	errorCode(t, e, "IDEMPOTENCY_KEY_REUSED")
	iv := invite(t, s, a, sid)
	v := accept(t, s, b, iv.Code, "小满")
	if v.Status != "joined" || len(v.Required) != 1 {
		t.Fatalf("first join: %+v", v)
	}
	_, e = s.Preview(ctx, other, iv.Code)
	errorCode(t, e, "NOT_FOUND")
	second := invite(t, s, a, sid)
	v = accept(t, s, c, second.Code, "新伙伴")
	if v.Status != "waiting" || len(v.Required) != 2 || len(v.Approved) != 1 {
		t.Fatalf("waiting: %+v", v)
	}
	_, e = s.Members(ctx, c, sid, paging.Query{Limit: 20})
	errorCode(t, e, "NOT_FOUND")
	// A second invite merges into the existing candidate and carries the inviter's consent.
	merged := invite(t, s, b, sid)
	joined := accept(t, s, c, merged.Code, "另一个昵称")
	if joined.ID != v.ID || joined.Status != "joined" || *joined.Nickname != "新伙伴" {
		t.Fatalf("merge: %+v", joined)
	}
	v, e = s.Invitation(ctx, a, v.ID)
	if e != nil || len(v.Required) != 2 {
		t.Fatalf("snapshot changed: %+v %v", v, e)
	}
	members, e := s.Members(ctx, a, sid, paging.Query{Limit: 2})
	if e != nil || len(members.Items) != 2 || members.Next == nil {
		t.Fatalf("members: %+v %v", members, e)
	}
	tail, e := s.Members(ctx, a, sid, paging.Query{Limit: 2, Cursor: *members.Next})
	if e != nil || len(tail.Items) != 1 {
		t.Fatal("pagination", e)
	}
	another := made(t, s, a, "第二空间")
	_, e = s.Approve(ctx, a, identifier.New(), another.Space.ID, second.Invitation.ID, identifier.New())
	errorCode(t, e, "NOT_FOUND")
	if _, e = s.List(ctx, a, paging.Query{Limit: 20, Cursor: *members.Next}); e == nil {
		t.Fatal("cross-scope cursor accepted")
	}
	// Restart after durable commit: a fresh worker projects all pending events.
	w := notification.Worker{Pool: pool}
	for {
		worked, e := w.Process(ctx)
		if e != nil {
			t.Fatal(e)
		}
		if !worked {
			break
		}
	}
	notices, e := s.Notifications(ctx, c, paging.Query{Limit: 100}, false)
	if e != nil || len(notices.Items) == 0 {
		t.Fatal("missing notices", e)
	}
	n := notices.Items[0]
	_, e = s.ReadNotification(ctx, other, identifier.New(), n.ID)
	errorCode(t, e, "NOT_FOUND")
	r, e := s.ReadNotification(ctx, c, identifier.New(), n.ID)
	if e != nil {
		t.Fatal(e)
	}
	var read notification.Notification
	_ = json.Unmarshal(r.Body, &read)
	if read.ReadAt == nil {
		t.Fatal("unread")
	}
	// Projection reruns and an abandoned lease remain duplicate-safe.
	var before int
	if e = pool.QueryRow(ctx, "SELECT count(*) FROM notifications").Scan(&before); e != nil {
		t.Fatal(e)
	}
	if _, e = pool.Exec(ctx, "UPDATE notification_events SET status='processing',lease_until=now()-interval '1 second',lease_owner=$1", identifier.New()); e != nil {
		t.Fatal(e)
	}
	for {
		ok, e := w.Process(ctx)
		if e != nil {
			t.Fatal(e)
		}
		if !ok {
			break
		}
	}
	var after int
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM notifications").Scan(&after)
	if before != after {
		t.Fatal("duplicate notification")
	}
	// Account-wide keys conflict with other operations without a second business effect.
	_, e = s.Nickname(ctx, a, key, sid, "昵称", identifier.New())
	errorCode(t, e, "IDEMPOTENCY_KEY_REUSED")
}
func TestWaitingEmptySpaceAndChangingApprovalSet(t *testing.T) {
	pool := testdb.New(t)
	s, _ := New(pool, make([]byte, 32))
	ctx := context.Background()
	a := person(t, pool, "甲")
	b := person(t, pool, "乙")
	c := person(t, pool, "丙")
	d := person(t, pool, "丁")
	home := made(t, s, a, "日常")
	sid := home.Space.ID
	accept(t, s, b, invite(t, s, a, sid).Code, "乙")
	ic := invite(t, s, a, sid)
	vc := accept(t, s, c, ic.Code, "丙")
	id := invite(t, s, a, sid)
	vd := accept(t, s, d, id.Code, "丁")
	// T06 owns public leave/restore; exercise their shared reconciliation boundary in a real transaction.
	tx, e := pool.Begin(ctx)
	if e != nil {
		t.Fatal(e)
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, "SELECT id FROM spaces WHERE id=$1 FOR UPDATE", sid); e != nil {
		t.Fatal(e)
	}
	if _, e = tx.Exec(ctx, "UPDATE memberships SET status='left',left_at=now() WHERE space_id=$1", sid); e != nil {
		t.Fatal(e)
	}
	if e = reconcile(ctx, tx, sid, a.UserID, identifier.New()); e != nil {
		t.Fatal(e)
	}
	v, e := readInvitation(ctx, tx, vc.ID)
	if e != nil || v.Status != "waiting" || len(v.Required) != 0 {
		t.Fatal("empty space joined", e)
	}
	if _, e = tx.Exec(ctx, "UPDATE memberships SET status='active',left_at=NULL WHERE id=$1", home.Member.ID); e != nil {
		t.Fatal(e)
	}
	if e = reconcile(ctx, tx, sid, a.UserID, identifier.New()); e != nil {
		t.Fatal(e)
	}
	v, e = readInvitation(ctx, tx, vc.ID)
	if e != nil || v.Status != "joined" {
		t.Fatal("restore did not join", e)
	}
	v, e = readInvitation(ctx, tx, vd.ID)
	if e != nil || v.Status != "waiting" || len(v.Required) != 2 {
		t.Fatal("new member must consent", e)
	}
	if e = tx.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	_, e = s.Approve(ctx, c, identifier.New(), sid, vd.ID, identifier.New())
	if e != nil {
		t.Fatal(e)
	}
	// Expired unused credential is unavailable, accepted applications survive expiry.
	ex := invite(t, s, a, sid)
	_, e = pool.Exec(ctx, "UPDATE invitations SET expires_at=now()-interval '1 day' WHERE id=$1", ex.Invitation.ID)
	if e != nil {
		t.Fatal(e)
	}
	_, e = s.Preview(ctx, b, ex.Code)
	errorCode(t, e, "NOT_FOUND")
	// Replaying an invitation creation returns the same encrypted credential.
	key := identifier.New()
	first, e := s.CreateInvitation(ctx, a, key, sid, identifier.New())
	if e != nil {
		t.Fatal(e)
	}
	again, e := s.CreateInvitation(ctx, a, key, sid, identifier.New())
	if e != nil || again.Code != first.Code {
		t.Fatal("code replay", e)
	}
	var stored string
	_ = pool.QueryRow(ctx, "SELECT response_body::text FROM commands WHERE actor_user_id=$1 AND idempotency_key=$2", a.UserID, key).Scan(&stored)
	var raw map[string]any
	_ = json.Unmarshal([]byte(stored), &raw)
	if raw["invite_code"] != nil {
		t.Fatal("credential in command JSON")
	}
}

// A failing channel enqueue rolls the projection back while leaving business committed.
type testChannel struct{ fail bool }

func (c testChannel) Enqueue(ctx context.Context, tx pgx.Tx, e notification.Event) error {
	if c.fail {
		return errors.New("simulated channel job failure")
	}
	_, err := tx.Exec(ctx, "INSERT INTO test_channel_jobs(event_id) VALUES($1) ON CONFLICT DO NOTHING", e.ID)
	return err
}
func TestNotificationProjectionRollbackAndChannelSeam(t *testing.T) {
	pool := testdb.New(t)
	s, _ := New(pool, make([]byte, 32))
	ctx := context.Background()
	a := person(t, pool, "甲")
	b := person(t, pool, "乙")
	home := made(t, s, a, "空间")
	v := accept(t, s, b, invite(t, s, a, home.Space.ID).Code, "乙")
	if v.Status != "joined" {
		t.Fatal(v.Status)
	}
	_, e := pool.Exec(ctx, "CREATE TABLE test_channel_jobs(event_id uuid PRIMARY KEY)")
	if e != nil {
		t.Fatal(e)
	}
	w := notification.Worker{Pool: pool, Channels: []notification.Channel{testChannel{true}}}
	if _, e = w.Process(ctx); e == nil {
		t.Fatal("failure missing")
	}
	var n int
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM notifications").Scan(&n)
	if n != 0 {
		t.Fatal("partial notification commit")
	}
	_, e = pool.Exec(ctx, "UPDATE notification_events SET available_at=now()")
	if e != nil {
		t.Fatal(e)
	}
	w.Channels = []notification.Channel{testChannel{false}}
	if _, e = w.Process(ctx); e != nil {
		t.Fatal(e)
	}
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM test_channel_jobs").Scan(&n)
	if n != 1 {
		t.Fatal("channel not enqueued")
	}
	members, e := s.Members(ctx, a, home.Space.ID, paging.Query{Limit: 20})
	if e != nil || len(members.Items) != 2 {
		t.Fatal("business lost", e)
	}
}

func TestInviteClaimConcurrencyAndAtomicRollback(t *testing.T) {
	pool := testdb.New(t)
	s, _ := New(pool, make([]byte, 32))
	ctx := context.Background()
	a := person(t, pool, "甲")
	b := person(t, pool, "乙")
	c := person(t, pool, "丙")
	home := made(t, s, a, "空间")
	iv := invite(t, s, a, home.Space.ID)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for _, p := range []account.Principal{b, c} {
		wg.Go(func() {
			_, e := s.Accept(ctx, p, identifier.New(), identifier.New(), AcceptInput{iv.Code, "伙伴"})
			errs <- e
		})
	}
	wg.Wait()
	close(errs)
	wins := 0
	for e := range errs {
		if e == nil {
			wins++
		} else {
			errorCode(t, e, "NOT_FOUND")
		}
	}
	if wins != 1 {
		t.Fatal("invite bound more than once")
	}
	v, e := s.Invitation(ctx, a, iv.Invitation.ID)
	if e != nil {
		t.Fatal(e)
	}
	candidate := b
	if *v.Candidate == c.UserID {
		candidate = c
	}
	old := v.Required
	// A different operation key still cannot duplicate membership or its join event.
	again := accept(t, s, candidate, iv.Code, "修改后的昵称")
	if again.Status != "joined" || len(again.Required) != len(old) {
		t.Fatal("duplicate accept changed snapshot")
	}
	var events int
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM notification_events WHERE event_type='member.joined'").Scan(&events)
	if events != 1 {
		t.Fatal("join event repeated")
	}
	// Roll back a space join when the final durable event fails.
	other := made(t, s, a, "回滚空间")
	bad := invite(t, s, a, other.Space.ID)
	_, e = pool.Exec(ctx, `CREATE FUNCTION reject_event() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'injected'; END $$; CREATE TRIGGER reject_event BEFORE INSERT ON notification_events FOR EACH ROW EXECUTE FUNCTION reject_event()`)
	if e != nil {
		t.Fatal(e)
	}
	key := identifier.New()
	_, e = s.Accept(ctx, b, key, identifier.New(), AcceptInput{bad.Code, "乙"})
	if e == nil {
		t.Fatal("injected failure ignored")
	}
	var count int
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM memberships WHERE space_id=$1 AND user_id=$2", other.Space.ID, b.UserID).Scan(&count)
	if count != 0 {
		t.Fatal("partial membership")
	}
	_ = pool.QueryRow(ctx, "SELECT count(*) FROM commands WHERE actor_user_id=$1 AND idempotency_key=$2", b.UserID, key).Scan(&count)
	if count != 0 {
		t.Fatal("partial command")
	}
	_, e = pool.Exec(ctx, "DROP TRIGGER reject_event ON notification_events")
	if e != nil {
		t.Fatal(e)
	}
	r, e := s.Accept(ctx, b, key, identifier.New(), AcceptInput{bad.Code, "乙"})
	if e != nil {
		t.Fatal(e)
	}
	var restored Invitation
	_ = json.Unmarshal(r.Body, &restored)
	if restored.Status != "joined" {
		t.Fatal("retry failed")
	}
	// Zero balance in this space is independent of the same account elsewhere.
	_, e = pool.Exec(ctx, "UPDATE memberships SET balance=42 WHERE space_id=$1 AND user_id=$2", home.Space.ID, candidate.UserID)
	if e != nil {
		t.Fatal(e)
	}
	list, e := s.Members(ctx, a, other.Space.ID, paging.Query{Limit: 20})
	if e != nil {
		t.Fatal(e)
	}
	for _, m := range list.Items {
		if m.Balance != 0 {
			t.Fatal("cross-space balance")
		}
	}
}
