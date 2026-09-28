package account

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

type rowReader interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

func readUser(ctx context.Context, db rowReader, id string) (User, error) {
	var u User
	err := db.QueryRow(ctx, "SELECT id,display_name,theme,created_at FROM users WHERE id=$1", id).Scan(&u.ID, &u.DisplayName, &u.Theme, &u.CreatedAt)
	u.CreatedAt = u.CreatedAt.UTC()
	return u, err
}
func (s *Service) Me(ctx context.Context, p Principal) (User, error) {
	return readUser(ctx, s.pool, p.UserID)
}

type ProfileUpdate struct {
	DisplayName *string `json:"display_name,omitempty"`
	Theme       *string `json:"theme,omitempty"`
}

func (s *Service) Update(ctx context.Context, p Principal, key string, change ProfileUpdate) (User, error) {
	if !identifier.Valid(key) {
		return User{}, apperror.New("INVALID_REQUEST")
	}
	if change.DisplayName == nil && change.Theme == nil {
		return User{}, fieldError("display_name", "CHANGE_REQUIRED")
	}
	if change.DisplayName != nil {
		v := strings.TrimSpace(*change.DisplayName)
		if !utf8.ValidString(v) || utf8.RuneCountInString(v) < 1 || utf8.RuneCountInString(v) > 60 {
			return User{}, fieldError("display_name", "NAME_LENGTH")
		}
		change.DisplayName = &v
	}
	if change.Theme != nil && *change.Theme != "apricot" && *change.Theme != "celadon" && *change.Theme != "rose" {
		return User{}, fieldError("theme", "INVALID_THEME")
	}
	body, _ := json.Marshal(change)
	hash := sha256.Sum256(append([]byte("updateMe:"), body...))
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return User{}, err
	}
	defer rollback(tx)
	var id string
	if err = tx.QueryRow(ctx, "SELECT id FROM users WHERE id=$1 FOR UPDATE", p.UserID).Scan(&id); err != nil {
		return User{}, err
	}
	if err = tx.QueryRow(ctx, "SELECT id FROM sessions WHERE id=$1 AND user_id=$2 AND revoked_at IS NULL AND expires_at>clock_timestamp() FOR SHARE", p.SessionID, p.UserID).Scan(&id); errors.Is(err, pgx.ErrNoRows) {
		return User{}, apperror.New("UNAUTHENTICATED")
	} else if err != nil {
		return User{}, err
	}
	// Same advisory key as the space command writer, so keys are account-wide.
	sum := sha256.Sum256([]byte(p.UserID + ":" + key))
	if err = lock(ctx, tx, sum[:]); err != nil {
		return User{}, err
	}
	var oldHash, stored []byte
	err = tx.QueryRow(ctx, "SELECT request_hash,response_body FROM commands WHERE actor_user_id=$1 AND idempotency_key=$2", p.UserID, key).Scan(&oldHash, &stored)
	if err == nil {
		if !bytes.Equal(oldHash, hash[:]) {
			return User{}, apperror.New("IDEMPOTENCY_KEY_REUSED")
		}
		var u User
		if err = json.Unmarshal(stored, &u); err != nil {
			return User{}, fmt.Errorf("decode saved profile: %w", err)
		}
		return u, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return User{}, err
	}
	_, err = tx.Exec(ctx, "UPDATE users SET display_name=COALESCE($2,display_name),theme=COALESCE($3,theme),updated_at=clock_timestamp() WHERE id=$1", p.UserID, change.DisplayName, change.Theme)
	if err != nil {
		return User{}, err
	}
	user, err := readUser(ctx, tx, p.UserID)
	if err != nil {
		return User{}, err
	}
	result, _ := json.Marshal(user)
	_, err = tx.Exec(ctx, `INSERT INTO commands(actor_user_id,idempotency_key,operation_name,request_hash,result_status,http_status,response_body) VALUES($1,$2,'updateMe',$3,'succeeded',200,$4)`, p.UserID, key, hash[:], result)
	if err != nil {
		return User{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return User{}, err
	}
	return user, nil
}
