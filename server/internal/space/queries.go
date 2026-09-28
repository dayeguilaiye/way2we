package space

import (
	"context"
	"github.com/jackc/pgx/v5"
	"way2we/server/internal/account"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
	"way2we/server/internal/platform/paging"
)

func (s *Service) List(ctx context.Context, p account.Principal, q paging.Query) (out paging.Page[Summary], err error) {
	out.Items = []Summary{}
	scope := "spaces:" + p.UserID
	pos, e := q.Decode(scope)
	if e != nil {
		return out, e
	}
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		rows, e := tx.Query(ctx, `SELECT s.id,s.name,s.created_at,m.id,m.status FROM spaces s JOIN memberships m ON m.space_id=s.id WHERE m.user_id=$1 AND (s.created_at,s.id)<($2,$3) ORDER BY s.created_at DESC,s.id DESC LIMIT $4`, p.UserID, pos.Time, pos.ID, q.Limit+1)
		if e != nil {
			return e
		}
		defer rows.Close()
		for rows.Next() {
			var v Summary
			if e = rows.Scan(&v.Space.ID, &v.Space.Name, &v.Space.CreatedAt, &v.MemberID, &v.Status); e != nil {
				return e
			}
			out.Items = append(out.Items, v)
		}
		return rows.Err()
	})
	if len(out.Items) > q.Limit {
		out.Items = out.Items[:q.Limit]
		v := out.Items[len(out.Items)-1]
		out.Next = paging.Next(scope, v.Space.CreatedAt, v.Space.ID)
	}
	return
}
func (s *Service) Members(ctx context.Context, p account.Principal, sid string, q paging.Query) (out paging.Page[Member], err error) {
	out.Items = []Member{}
	if !identifier.Valid(sid) {
		return out, apperror.New("NOT_FOUND")
	}
	scope := "members:" + p.UserID + ":" + sid
	pos, e := q.Decode(scope)
	if e != nil {
		return out, e
	}
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		if e := active(ctx, tx, sid, p.UserID); e != nil {
			return e
		}
		rows, e := tx.Query(ctx, `SELECT id,space_id,user_id,nickname,status,balance,joined_at,left_at FROM memberships WHERE space_id=$1 AND (joined_at,id)<($2,$3) ORDER BY joined_at DESC,id DESC LIMIT $4`, sid, pos.Time, pos.ID, q.Limit+1)
		if e != nil {
			return e
		}
		defer rows.Close()
		for rows.Next() {
			var v Member
			if e = rows.Scan(&v.ID, &v.SpaceID, &v.UserID, &v.Nickname, &v.Status, &v.Balance, &v.JoinedAt, &v.LeftAt); e != nil {
				return e
			}
			out.Items = append(out.Items, v)
		}
		return rows.Err()
	})
	if len(out.Items) > q.Limit {
		out.Items = out.Items[:q.Limit]
		v := out.Items[len(out.Items)-1]
		out.Next = paging.Next(scope, v.JoinedAt, v.ID)
	}
	return
}
func (s *Service) Invitations(ctx context.Context, p account.Principal, sid string, q paging.Query) (out paging.Page[Invitation], err error) {
	out.Items = []Invitation{}
	if !identifier.Valid(sid) {
		return out, apperror.New("NOT_FOUND")
	}
	scope := "invitations:" + p.UserID + ":" + sid
	pos, e := q.Decode(scope)
	if e != nil {
		return out, e
	}
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		if e := active(ctx, tx, sid, p.UserID); e != nil {
			return e
		}
		rows, e := tx.Query(ctx, `SELECT id FROM invitations WHERE space_id=$1 AND canonical_id IS NULL AND (created_at,id)<($2,$3) ORDER BY created_at DESC,id DESC LIMIT $4`, sid, pos.Time, pos.ID, q.Limit+1)
		if e != nil {
			return e
		}
		ids := []string{}
		for rows.Next() {
			var id string
			if e = rows.Scan(&id); e != nil {
				rows.Close()
				return e
			}
			ids = append(ids, id)
		}
		e = rows.Err()
		rows.Close()
		if e != nil {
			return e
		}
		for _, id := range ids {
			v, e := readInvitation(ctx, tx, id)
			if e != nil {
				return e
			}
			out.Items = append(out.Items, v)
		}
		return nil
	})
	if len(out.Items) > q.Limit {
		out.Items = out.Items[:q.Limit]
		v := out.Items[len(out.Items)-1]
		out.Next = paging.Next(scope, v.CreatedAt, v.ID)
	}
	return
}
