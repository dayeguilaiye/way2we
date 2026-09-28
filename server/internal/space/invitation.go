package space

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base32"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"regexp"
	"strings"
	"time"
	"way2we/server/internal/account"
	"way2we/server/internal/notification"
	"way2we/server/internal/platform/apperror"
	"way2we/server/internal/platform/identifier"
)

type Invitation struct {
	ID         string     `json:"id"`
	SpaceID    string     `json:"space_id"`
	SpaceName  string     `json:"space_name"`
	Inviter    string     `json:"inviter_nickname"`
	Candidate  *string    `json:"candidate_user_id"`
	Nickname   *string    `json:"candidate_display_name"`
	Status     string     `json:"status"`
	AcceptedAt *time.Time `json:"accepted_at"`
	ExpiresAt  time.Time  `json:"expires_at"`
	Required   []string   `json:"required_member_ids"`
	Approved   []string   `json:"approved_member_ids"`
	CreatedAt  time.Time  `json:"-"`
}
type InvitationCreated struct {
	Invitation Invitation `json:"invitation"`
	Code       string     `json:"invite_code"`
}
type Preview struct {
	SpaceName string    `json:"space_name"`
	Inviter   string    `json:"inviter_nickname"`
	ExpiresAt time.Time `json:"expires_at"`
}
type AcceptInput struct {
	Code     string `json:"invite_code"`
	Nickname string `json:"nickname"`
}

var codePattern = regexp.MustCompile(`^[A-Z2-7]{20}$`)

func codeDigest(code string) ([]byte, error) {
	if !codePattern.MatchString(code) {
		return nil, &apperror.Error{Code: "VALIDATION_FAILED", Fields: []apperror.Field{{Field: "invite_code", Code: "INVALID_FORMAT"}}}
	}
	v := sha256.Sum256([]byte(code))
	return v[:], nil
}
func readInvitation(ctx context.Context, tx pgx.Tx, id string) (v Invitation, err error) {
	err = tx.QueryRow(ctx, `SELECT i.id,i.space_id,s.name,m.nickname,i.candidate_user_id,i.candidate_nickname,CASE WHEN i.status='waiting' AND i.accepted_at IS NULL AND i.expires_at<=clock_timestamp() THEN 'expired' ELSE i.status END,i.accepted_at,i.expires_at,i.required_snapshot,i.approved_snapshot,i.created_at FROM invitations i JOIN spaces s ON s.id=i.space_id JOIN memberships m ON m.id=i.inviter_member_id WHERE i.id=(SELECT COALESCE(canonical_id,id) FROM invitations WHERE id=$1)`, id).Scan(&v.ID, &v.SpaceID, &v.SpaceName, &v.Inviter, &v.Candidate, &v.Nickname, &v.Status, &v.AcceptedAt, &v.ExpiresAt, &v.Required, &v.Approved, &v.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return v, apperror.New("NOT_FOUND")
	}
	if err != nil {
		return v, err
	}
	if v.Status != "joined" {
		err = tx.QueryRow(ctx, `SELECT COALESCE(array_agg(m.id ORDER BY m.id),'{}'::uuid[]), COALESCE(array_agg(m.id ORDER BY m.id) FILTER(WHERE a.member_id IS NOT NULL),'{}'::uuid[]) FROM memberships m LEFT JOIN invitation_approvals a ON a.member_id=m.id AND a.invitation_id=$2 WHERE m.space_id=$1 AND m.status='active'`, v.SpaceID, v.ID).Scan(&v.Required, &v.Approved)
	}
	return
}
func candidateOrActive(ctx context.Context, tx pgx.Tx, id, uid string) error {
	v, e := readInvitation(ctx, tx, id)
	if e != nil {
		return e
	}
	if v.Candidate != nil && *v.Candidate == uid {
		return nil
	}
	return active(ctx, tx, v.SpaceID, uid)
}
func (s *Service) Invitation(ctx context.Context, p account.Principal, id string) (v Invitation, err error) {
	if !identifier.Valid(id) {
		return v, apperror.New("NOT_FOUND")
	}
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		if e := candidateOrActive(ctx, tx, id, p.UserID); e != nil {
			return e
		}
		v, err = readInvitation(ctx, tx, id)
		return err
	})
	return
}
func (s *Service) CreateInvitation(ctx context.Context, p account.Principal, key, sid, rid string) (InvitationCreated, error) {
	res, err := s.run(ctx, p, key, "createInvitation", sid, struct{}{}, func(ctx context.Context, tx pgx.Tx) error { return active(ctx, tx, sid, p.UserID) }, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		id := identifier.New()
		random := make([]byte, 13)
		if _, e := rand.Read(random); e != nil {
			return Result{}, e
		}
		code := base32.StdEncoding.WithPadding(base32.NoPadding).EncodeToString(random)[:20]
		digest, _ := codeDigest(code)
		nonce := make([]byte, s.seal.NonceSize())
		if _, e := rand.Read(nonce); e != nil {
			return Result{}, e
		}
		encrypted := s.seal.Seal(nonce, nonce, []byte(code), []byte("invitation:"+id))
		_, e := tx.Exec(ctx, `INSERT INTO invitations(id,space_id,inviter_member_id,code_digest,code_ciphertext,expires_at) SELECT $1,$2,id,$4,$5,clock_timestamp()+interval '7 days' FROM memberships WHERE space_id=$2 AND user_id=$3`, id, sid, p.UserID, digest, encrypted)
		if e != nil {
			return Result{}, e
		}
		_, e = tx.Exec(ctx, `INSERT INTO invitation_approvals(space_id,invitation_id,member_id) SELECT $1,$2,id FROM memberships WHERE space_id=$1 AND user_id=$3`, sid, id, p.UserID)
		if e != nil {
			return Result{}, e
		}
		if e = audit(ctx, tx, sid, p.UserID, "invitation.created", id, rid); e != nil {
			return Result{}, e
		}
		v, e := readInvitation(ctx, tx, id)
		if e != nil {
			return Result{}, e
		}
		return result(201, v)
	})
	if err != nil {
		return InvitationCreated{}, err
	}
	var v Invitation
	if err = json.Unmarshal(res.Body, &v); err != nil {
		return InvitationCreated{}, err
	}
	var raw []byte
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		if e := active(ctx, tx, sid, p.UserID); e != nil {
			return e
		}
		return tx.QueryRow(ctx, "SELECT code_ciphertext FROM invitations WHERE id=$1 AND space_id=$2", v.ID, sid).Scan(&raw)
	})
	if err != nil {
		return InvitationCreated{}, err
	}
	n := s.seal.NonceSize()
	if len(raw) < n {
		return InvitationCreated{}, errors.New("invalid invitation ciphertext")
	}
	code, err := s.seal.Open(nil, raw[:n], raw[n:], []byte("invitation:"+v.ID))
	return InvitationCreated{v, string(code)}, err
}
func usableCode(ctx context.Context, tx pgx.Tx, digest []byte, uid string) (id, sid string, err error) {
	err = tx.QueryRow(ctx, `SELECT id,space_id FROM invitations WHERE code_digest=$1 AND (candidate_user_id=$2 OR (candidate_user_id IS NULL AND status='waiting' AND expires_at>clock_timestamp()))`, digest, uid).Scan(&id, &sid)
	if errors.Is(err, pgx.ErrNoRows) {
		err = apperror.New("NOT_FOUND")
	}
	return
}
func (s *Service) Preview(ctx context.Context, p account.Principal, code string) (v Preview, err error) {
	digest, err := codeDigest(code)
	if err != nil {
		return v, err
	}
	err = s.read(ctx, p, func(tx pgx.Tx) error {
		id, _, e := usableCode(ctx, tx, digest, p.UserID)
		if e != nil {
			return e
		}
		i, e := readInvitation(ctx, tx, id)
		v = Preview{i.SpaceName, i.Inviter, i.ExpiresAt}
		return e
	})
	return
}
func (s *Service) Accept(ctx context.Context, p account.Principal, key, rid string, in AcceptInput) (Result, error) {
	in.Nickname = strings.TrimSpace(in.Nickname)
	if err := validName(in.Nickname, "nickname"); err != nil {
		return Result{}, err
	}
	digest, err := codeDigest(in.Code)
	if err != nil {
		return Result{}, err
	}
	var id, sid string
	err = s.read(ctx, p, func(tx pgx.Tx) error { var e error; id, sid, e = usableCode(ctx, tx, digest, p.UserID); return e })
	if err != nil {
		return Result{}, err
	}
	// The command fingerprint contains the digest, never the invitation credential.
	params := struct {
		Digest   []byte
		Nickname string
	}{digest, in.Nickname}
	return s.run(ctx, p, key, "acceptInvitation", sid, params, func(ctx context.Context, tx pgx.Tx) error { _, _, e := usableCode(ctx, tx, digest, p.UserID); return e }, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		v, e := readInvitation(ctx, tx, id)
		if e != nil {
			return Result{}, e
		}
		if v.Candidate != nil {
			return result(200, v)
		}
		var existing string
		e = tx.QueryRow(ctx, `SELECT id FROM invitations WHERE space_id=$1 AND candidate_user_id=$2 AND status='waiting' AND canonical_id IS NULL ORDER BY accepted_at,id LIMIT 1`, sid, p.UserID).Scan(&existing)
		if e != nil && !errors.Is(e, pgx.ErrNoRows) {
			return Result{}, e
		}
		var canonical any
		if existing != "" {
			canonical = existing
		}
		_, e = tx.Exec(ctx, `UPDATE invitations SET candidate_user_id=$2,candidate_nickname=$3,accepted_at=clock_timestamp(),canonical_id=$4 WHERE id=$1`, id, p.UserID, in.Nickname, canonical)
		if e != nil {
			return Result{}, e
		}
		if existing != "" {
			_, e = tx.Exec(ctx, `INSERT INTO invitation_approvals(space_id,invitation_id,member_id) SELECT space_id,$2,member_id FROM invitation_approvals WHERE invitation_id=$1 ON CONFLICT DO NOTHING`, id, existing)
			if e != nil {
				return Result{}, e
			}
			id = existing
		}
		if e = audit(ctx, tx, sid, p.UserID, "invitation.accepted", id, rid); e != nil {
			return Result{}, e
		}
		// Historical membership is stable; restoring it requires no fresh approval.
		m, e := readMember(ctx, tx, sid, p.UserID)
		if e != nil && !errors.Is(e, pgx.ErrNoRows) {
			return Result{}, e
		}
		if e == nil {
			if m.Status == "left" {
				if _, e = tx.Exec(ctx, "UPDATE memberships SET status='active',left_at=NULL WHERE id=$1", m.ID); e != nil {
					return Result{}, e
				}
			}
			if m.Status == "left" {
				if e = audit(ctx, tx, sid, p.UserID, "member.restored", m.ID, rid); e != nil {
					return Result{}, e
				}
				restored, e := readInvitation(ctx, tx, id)
				if e != nil {
					return Result{}, e
				}
				if e = progressEvent(ctx, tx, restored, p.UserID, rid, "member.restored", "伙伴已恢复参与。", true); e != nil {
					return Result{}, e
				}
			}
			if e = joinExisting(ctx, tx, id); e != nil {
				return Result{}, e
			}
		}
		if e = reconcile(ctx, tx, sid, p.UserID, rid); e != nil {
			return Result{}, e
		}
		v, e = readInvitation(ctx, tx, id)
		if e != nil {
			return Result{}, e
		}
		if v.Status == "waiting" {
			if e = progressEvent(ctx, tx, v, p.UserID, rid, "invitation.accepted", "有新的加入申请，请查看进度。", true); e != nil {
				return Result{}, e
			}
		}
		return result(200, v)
	})
}
func joinExisting(ctx context.Context, tx pgx.Tx, id string) error {
	_, e := tx.Exec(ctx, `UPDATE invitations SET status='joined',required_snapshot='{}',approved_snapshot='{}' WHERE id=$1`, id)
	return e
}
func (s *Service) Approve(ctx context.Context, p account.Principal, key, sid, id, rid string) (Result, error) {
	if !identifier.Valid(id) {
		return Result{}, apperror.New("NOT_FOUND")
	}
	return s.run(ctx, p, key, "approveInvitation", sid, map[string]string{"invitation_id": id}, func(ctx context.Context, tx pgx.Tx) error {
		if e := active(ctx, tx, sid, p.UserID); e != nil {
			return e
		}
		v, e := readInvitation(ctx, tx, id)
		if e != nil {
			return e
		}
		if v.SpaceID != sid {
			return apperror.New("NOT_FOUND")
		}
		return nil
	}, func(ctx context.Context, tx pgx.Tx) (Result, error) {
		v, e := readInvitation(ctx, tx, id)
		if e != nil {
			return Result{}, e
		}
		if v.Status == "joined" {
			return result(200, v)
		}
		if v.Status == "expired" {
			return Result{}, apperror.New("RESOURCE_STATE_CONFLICT")
		}
		tag, e := tx.Exec(ctx, `INSERT INTO invitation_approvals(space_id,invitation_id,member_id) SELECT $1,$2,id FROM memberships WHERE space_id=$1 AND user_id=$3 ON CONFLICT DO NOTHING`, sid, v.ID, p.UserID)
		if e != nil {
			return Result{}, e
		}
		if tag.RowsAffected() > 0 {
			if e = audit(ctx, tx, sid, p.UserID, "invitation.approved", v.ID, rid); e != nil {
				return Result{}, e
			}
		}
		if e = reconcile(ctx, tx, sid, p.UserID, rid); e != nil {
			return Result{}, e
		}
		v, e = readInvitation(ctx, tx, v.ID)
		if e != nil {
			return Result{}, e
		}
		if tag.RowsAffected() > 0 && v.Status == "waiting" && v.Candidate != nil {
			if e = progressEvent(ctx, tx, v, p.UserID, rid, "invitation.approved", "加入申请有新进展。", false); e != nil {
				return Result{}, e
			}
		}
		return result(200, v)
	})
}

// reconcile is called inside the space lock after every membership change.
// Re-read active members after each join: the new member must approve later applicants.
func reconcile(ctx context.Context, tx pgx.Tx, sid, actor, rid string) error {
	rows, e := tx.Query(ctx, `SELECT id FROM invitations WHERE space_id=$1 AND status='waiting' AND candidate_user_id IS NOT NULL AND canonical_id IS NULL ORDER BY accepted_at,id`, sid)
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
		if len(v.Required) == 0 || len(v.Required) != len(v.Approved) {
			continue
		}
		_, e = tx.Exec(ctx, `INSERT INTO memberships(id,space_id,user_id,nickname) VALUES($1,$2,$3,$4) ON CONFLICT(space_id,user_id) DO NOTHING`, identifier.New(), sid, *v.Candidate, *v.Nickname)
		if e != nil {
			return e
		}
		_, e = tx.Exec(ctx, `UPDATE invitations SET status='joined',required_snapshot=$2,approved_snapshot=$3 WHERE id=$1`, id, v.Required, v.Approved)
		if e != nil {
			return e
		}
		if e = audit(ctx, tx, sid, actor, "member.joined", id, rid); e != nil {
			return e
		}
		if e = progressEvent(ctx, tx, v, actor, rid, "member.joined", "新的伙伴已加入空间。", true); e != nil {
			return e
		}
	}
	return nil
}
func progressEvent(ctx context.Context, tx pgx.Tx, v Invitation, actor, rid, kind, summary string, all bool) error {
	recipients := []string{}
	if v.Candidate != nil {
		recipients = append(recipients, *v.Candidate)
	}
	if all {
		rows, e := tx.Query(ctx, "SELECT user_id FROM memberships WHERE space_id=$1 AND status='active' AND user_id<>$2", v.SpaceID, actor)
		if e != nil {
			return e
		}
		for rows.Next() {
			var uid string
			if e = rows.Scan(&uid); e != nil {
				rows.Close()
				return e
			}
			recipients = append(recipients, uid)
		}
		e = rows.Err()
		rows.Close()
		if e != nil {
			return e
		}
	}
	return notification.Record(ctx, tx, notification.Event{SpaceID: v.SpaceID, ActorID: actor, Type: kind, Recipients: recipients, Resource: notification.Resource{Kind: "invitation", ID: v.ID, SpaceID: v.SpaceID}, Summary: summary, RequestID: rid})
}
