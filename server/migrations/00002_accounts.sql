-- +goose Up
CREATE TABLE login_identities (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES users(id),
 provider text NOT NULL,
 subject text NOT NULL,
 verified_at timestamptz NOT NULL,
 CONSTRAINT login_identities_provider_subject_unique UNIQUE(provider,subject)
);
CREATE TABLE sessions (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES users(id),
 token_hash bytea NOT NULL UNIQUE CHECK(octet_length(token_hash)=32),
 created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL,
 revoked_at timestamptz
);
CREATE INDEX sessions_user ON sessions(user_id);
CREATE TABLE email_challenges (
 id uuid PRIMARY KEY,
 email_normalized text NOT NULL,
 code_hmac bytea,
 code_ciphertext bytea,
 attempt_count integer NOT NULL DEFAULT 0 CHECK(attempt_count BETWEEN 0 AND 5),
 created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL,
 consumed_at timestamptz,
 invalidated_at timestamptz,
 delivery_state text NOT NULL DEFAULT 'pending' CHECK(delivery_state IN ('pending','sending','sent','failed','expired')),
 delivery_attempts integer NOT NULL DEFAULT 0,
 available_at timestamptz NOT NULL,
 lease_until timestamptz,
 lease_token uuid,
 request_id text NOT NULL
);
CREATE INDEX email_challenges_email_created ON email_challenges(email_normalized,created_at DESC);
CREATE INDEX email_challenges_delivery ON email_challenges(available_at) WHERE delivery_state IN ('pending','sending');
CREATE TABLE auth_limits (
 bucket bytea PRIMARY KEY,
 attempts integer NOT NULL,
 expires_at timestamptz NOT NULL
);
-- +goose Down
DROP TABLE auth_limits;
DROP TABLE email_challenges;
DROP TABLE sessions;
DROP TABLE login_identities;
