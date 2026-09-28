package space

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"encoding/json"
	"errors"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"way2we/server/internal/account"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

type Service struct {
	pool   *pgxpool.Pool
	writer *Writer
	seal   cipher.AEAD
}

func New(pool *pgxpool.Pool, key []byte) (*Service, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}
	seal, err := cipher.NewGCM(block)
	return &Service{pool: pool, writer: NewWriter(pool), seal: seal}, err
}

type Space struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}
type Member struct {
	ID       string     `json:"id"`
	SpaceID  string     `json:"space_id"`
	UserID   string     `json:"user_id"`
	Nickname string     `json:"nickname"`
	Status   string     `json:"status"`
	Balance  int64      `json:"balance"`
	JoinedAt time.Time  `json:"joined_at"`
	LeftAt   *time.Time `json:"left_at"`
}
type Summary struct {
	Space    Space  `json:"space"`
	MemberID string `json:"my_member_id"`
	Status   string `json:"my_status"`
}
type Created struct {
	Space  Space  `json:"space"`
	Member Member `json:"member"`
}
type CreateInput struct {
	Name     string `json:"name"`
	Nickname string `json:"nickname"`
}

func validName(value, field string) error {
	if utf8.RuneCountInString(value) < 1 || utf8.RuneCountInString(value) > 60 {
		return &apperror.Error{Code: "VALIDATION_FAILED", Fields: []apperror.Field{{Field: field, Code: "INVALID_LENGTH"}}}
	}
	return nil
}
func authenticate(ctx context.Context, tx pgx.Tx, p account.Principal) error {
	var id string
	err := tx.QueryRow(ctx, "SELECT id FROM sessions WHERE id=$1 AND user_id=$2 AND revoked_at IS NULL AND expires_at>clock_timestamp()", p.SessionID, p.UserID).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return apperror.New("UNAUTHENTICATED")
	}
	return err
}
func active(ctx context.Context, tx pgx.Tx, spaceID, userID string) error {
	var status string
	err := tx.QueryRow(ctx, "SELECT status FROM memberships WHERE space_id=$1 AND user_id=$2", spaceID, userID).Scan(&status)
	if errors.Is(err, pgx.ErrNoRows) {
		return apperror.New("NOT_FOUND")
	}
	if err != nil {
		return err
	}
	if status != "active" {
		return apperror.New("MEMBERSHIP_INACTIVE")
	}
	return nil
}
func result(status int, v any) (Result, error) {
	raw, err := json.Marshal(v)
	return Result{Status: status, Body: raw}, err
}
func (s *Service) run(ctx context.Context, p account.Principal, key, op, sid string, params any, permission func(context.Context, pgx.Tx) error, apply func(context.Context, pgx.Tx) (Result, error)) (Result, error) {
	raw, err := json.Marshal(params)
	if err != nil {
		return Result{}, err
	}
	return s.writer.Run(ctx, Command{ActorID: p.UserID, Key: key, Operation: op, SpaceID: sid, Parameters: raw}, func(ctx context.Context, tx pgx.Tx) error {
		if err := authenticate(ctx, tx, p); err != nil {
			return err
		}
		if permission != nil {
			return permission(ctx, tx)
		}
		return nil
	}, apply)
}
func (s *Service) Create(ctx context.Context, p account.Principal, key, requestID string, in CreateInput) (Result, error) {
	in.Name = strings.TrimSpace(in.Name)
	in.Nickname = strings.TrimSpace(in.Nickname)
	if err := validName(in.Name, "name"); err != nil {
		return Result{}, err
	}
	if err := validName(in.Nickname, "nickname"); err != nil {
		return Result{}, err
	}
	return s.run(ctx, p, key, "createSpace", "", in, func(ctx context.Context, tx pgx.Tx) error {
		var sid string
		err := tx.QueryRow(ctx, "SELECT response_body->'space'->>'id' FROM commands WHERE actor_user_id=$1 AND idempotency_key=$2 AND operation_name='createSpace'", p.UserID, key).Scan(&sid)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		return active(ctx, tx, sid, p.UserID)
	}, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		sid := identifier.New()
		mid := identifier.New()
		if _, err := tx.Exec(ctx, "INSERT INTO spaces(id,name,created_by) VALUES($1,$2,$3)", sid, in.Name, p.UserID); err != nil {
			return Result{}, err
		}
		if _, err := tx.Exec(ctx, "INSERT INTO memberships(id,space_id,user_id,nickname) VALUES($1,$2,$3,$4)", mid, sid, p.UserID, in.Nickname); err != nil {
			return Result{}, err
		}
		if err := audit(ctx, tx, sid, p.UserID, "space.created", sid, requestID); err != nil {
			return Result{}, err
		}
		sp, err := readSpace(ctx, tx, sid)
		if err != nil {
			return Result{}, err
		}
		m, err := readMember(ctx, tx, sid, p.UserID)
		if err != nil {
			return Result{}, err
		}
		return result(201, Created{sp, m})
	})
}
func audit(ctx context.Context, tx pgx.Tx, sid, actor, action, resource, rid string) error {
	_, err := tx.Exec(ctx, "INSERT INTO space_audit(id,space_id,actor_user_id,action,resource_id,request_id) VALUES($1,$2,$3,$4,$5,$6)", identifier.New(), sid, actor, action, resource, rid)
	return err
}
func readSpace(ctx context.Context, tx pgx.Tx, id string) (Space, error) {
	var sp Space
	err := tx.QueryRow(ctx, "SELECT id,name,created_at FROM spaces WHERE id=$1", id).Scan(&sp.ID, &sp.Name, &sp.CreatedAt)
	return sp, err
}
func readMember(ctx context.Context, tx pgx.Tx, sid, uid string) (Member, error) {
	var m Member
	err := tx.QueryRow(ctx, "SELECT id,space_id,user_id,nickname,status,balance,joined_at,left_at FROM memberships WHERE space_id=$1 AND user_id=$2", sid, uid).Scan(&m.ID, &m.SpaceID, &m.UserID, &m.Nickname, &m.Status, &m.Balance, &m.JoinedAt, &m.LeftAt)
	return m, err
}
func (s *Service) read(ctx context.Context, p account.Principal, fn func(pgx.Tx) error) error {
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
	if err != nil {
		return err
	}
	defer tx.Rollback(context.WithoutCancel(ctx))
	if err = authenticate(ctx, tx, p); err != nil {
		return err
	}
	return fn(tx)
}
func (s *Service) Get(ctx context.Context, p account.Principal, sid string) (sp Space, err error) {
	if !identifier.Valid(sid) {
		return sp, apperror.New("NOT_FOUND")
	}
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		if e := active(ctx, tx, sid, p.UserID); e != nil {
			return e
		}
		sp, err = readSpace(ctx, tx, sid)
		return err
	})
	return
}
func (s *Service) Nickname(ctx context.Context, p account.Principal, key, sid, nickname, rid string) (Result, error) {
	nickname = strings.TrimSpace(nickname)
	if err := validName(nickname, "nickname"); err != nil {
		return Result{}, err
	}
	return s.run(ctx, p, key, "updateMyNickname", sid, map[string]string{"nickname": nickname}, func(ctx context.Context, tx pgx.Tx) error { return active(ctx, tx, sid, p.UserID) }, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		if _, err := tx.Exec(ctx, "UPDATE memberships SET nickname=$3 WHERE space_id=$1 AND user_id=$2", sid, p.UserID, nickname); err != nil {
			return Result{}, err
		}
		m, err := readMember(ctx, tx, sid, p.UserID)
		if err != nil {
			return Result{}, err
		}
		if err = audit(ctx, tx, sid, p.UserID, "member.nickname_updated", m.ID, rid); err != nil {
			return Result{}, err
		}
		return result(200, m)
	})
}
