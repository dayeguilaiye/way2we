-- +goose Up
CREATE TABLE invitations (
 id uuid PRIMARY KEY,
 space_id uuid NOT NULL REFERENCES spaces(id),
 inviter_member_id uuid NOT NULL,
 code_digest bytea NOT NULL UNIQUE CHECK (octet_length(code_digest)=32),
 code_ciphertext bytea NOT NULL,
 expires_at timestamptz NOT NULL,
 candidate_user_id uuid REFERENCES users(id),
 candidate_nickname text CHECK (char_length(candidate_nickname) BETWEEN 1 AND 60),
 accepted_at timestamptz,
 status text NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting','joined','expired')),
 canonical_id uuid REFERENCES invitations(id),
 required_snapshot uuid[] NOT NULL DEFAULT '{}',
 approved_snapshot uuid[] NOT NULL DEFAULT '{}',
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(space_id,id),
 FOREIGN KEY(space_id,inviter_member_id) REFERENCES memberships(space_id,id),
 CHECK ((candidate_user_id IS NULL)=(accepted_at IS NULL)),
 CHECK ((candidate_user_id IS NULL)=(candidate_nickname IS NULL))
);
CREATE INDEX invitations_pending ON invitations(space_id,accepted_at,id) WHERE status='waiting' AND canonical_id IS NULL;
CREATE UNIQUE INDEX invitations_candidate_pending ON invitations(space_id,candidate_user_id) WHERE status='waiting' AND canonical_id IS NULL AND candidate_user_id IS NOT NULL;
CREATE TABLE invitation_approvals (
 space_id uuid NOT NULL,
 invitation_id uuid NOT NULL,
 member_id uuid NOT NULL,
 approved_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(invitation_id,member_id),
 FOREIGN KEY(space_id,invitation_id) REFERENCES invitations(space_id,id),
 FOREIGN KEY(space_id,member_id) REFERENCES memberships(space_id,id)
);
CREATE TABLE space_audit (
 id uuid PRIMARY KEY,
 space_id uuid NOT NULL REFERENCES spaces(id),
 actor_user_id uuid NOT NULL REFERENCES users(id),
 action text NOT NULL,
 resource_id uuid NOT NULL,
 request_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE notification_events (
 id uuid PRIMARY KEY,
 space_id uuid NOT NULL REFERENCES spaces(id),
 event_type text NOT NULL,
 version integer NOT NULL DEFAULT 1,
 actor_user_id uuid NOT NULL REFERENCES users(id),
 recipient_ids uuid[] NOT NULL,
 resource_ref jsonb NOT NULL,
 payload jsonb NOT NULL,
 request_id uuid NOT NULL,
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','done','failed')),
 attempts integer NOT NULL DEFAULT 0,
 available_at timestamptz NOT NULL DEFAULT now(),
 lease_until timestamptz,
 lease_owner uuid,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notification_events_pending ON notification_events(available_at,id) WHERE status IN ('pending','processing');
CREATE TABLE notifications (
 id uuid PRIMARY KEY,
 event_id uuid NOT NULL REFERENCES notification_events(id),
 recipient_user_id uuid NOT NULL REFERENCES users(id),
 space_id uuid NOT NULL REFERENCES spaces(id),
 event_type text NOT NULL,
 resource_ref jsonb NOT NULL,
 summary text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 read_at timestamptz,
 UNIQUE(event_id,recipient_user_id)
);
CREATE INDEX notifications_recipient ON notifications(recipient_user_id,created_at DESC,id DESC);
-- +goose Down
DROP TABLE notifications;
DROP TABLE notification_events;
DROP TABLE space_audit;
DROP TABLE invitation_approvals;
DROP TABLE invitations;
