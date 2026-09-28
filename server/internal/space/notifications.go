package space

import (
	"context"
	"github.com/jackc/pgx/v5"
	"way2we/server/internal/account"
	"way2we/server/internal/notification"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
	"way2we/server/internal/platform/paging"
)

func (s *Service) Notifications(ctx context.Context, p account.Principal, q paging.Query, unread bool) (v paging.Page[notification.Notification], err error) {
	err = s.read(ctx, p, func(tx pgx.Tx) error { v, err = notification.List(ctx, tx, p.UserID, q, unread); return err })
	return
}
func (s *Service) ReadNotification(ctx context.Context, p account.Principal, key, id string) (Result, error) {
	if !identifier.Valid(id) {
		return Result{}, apperror.New("NOT_FOUND")
	}
	var v notification.Notification
	err := s.read(ctx, p, func(tx pgx.Tx) error { var e error; v, e = notification.Read(ctx, tx, p.UserID, id); return e })
	if err != nil {
		return Result{}, err
	}
	return s.run(ctx, p, key, "markNotificationRead", v.Resource.SpaceID, map[string]string{"notification_id": id}, func(ctx context.Context, tx pgx.Tx) error { _, e := notification.Read(ctx, tx, p.UserID, id); return e }, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		if _, e := tx.Exec(ctx, "UPDATE notifications SET read_at=COALESCE(read_at,clock_timestamp()) WHERE id=$1 AND recipient_user_id=$2", id, p.UserID); e != nil {
			return Result{}, e
		}
		v, e := notification.Read(ctx, tx, p.UserID, id)
		if e != nil {
			return Result{}, e
		}
		return result(200, v)
	})
}
