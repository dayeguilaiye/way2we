-- +goose Up
CREATE TABLE users (
 id uuid PRIMARY KEY,
 display_name text NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 60),
 theme text NOT NULL DEFAULT 'apricot' CHECK (theme IN ('apricot','celadon','rose')),
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE spaces (
 id uuid PRIMARY KEY,
 name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 60),
 created_by uuid NOT NULL REFERENCES users(id),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE memberships (
 id uuid PRIMARY KEY,
 space_id uuid NOT NULL REFERENCES spaces(id),
 user_id uuid NOT NULL REFERENCES users(id),
 nickname text NOT NULL CHECK (char_length(nickname) BETWEEN 1 AND 60),
 status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','left')),
 balance bigint NOT NULL DEFAULT 0 CHECK (balance BETWEEN -9007199254740991 AND 9007199254740991),
 joined_at timestamptz NOT NULL DEFAULT now(),
 left_at timestamptz,
 CONSTRAINT memberships_space_user_unique UNIQUE(space_id,user_id),
 CONSTRAINT memberships_space_id_unique UNIQUE(space_id,id),
 CONSTRAINT memberships_status_time CHECK ((status='active' AND left_at IS NULL) OR (status='left' AND left_at IS NOT NULL))
);
CREATE INDEX memberships_user_status ON memberships(user_id,status);
CREATE TABLE commands (
 actor_user_id uuid NOT NULL REFERENCES users(id),
 idempotency_key uuid NOT NULL,
 operation_name text NOT NULL,
 space_id uuid REFERENCES spaces(id),
 request_hash bytea NOT NULL CHECK (octet_length(request_hash)=32),
 result_status text NOT NULL CHECK (result_status IN ('succeeded','rejected')),
 http_status integer NOT NULL CHECK (http_status BETWEEN 200 AND 499),
 response_body jsonb NOT NULL,
 resource_refs jsonb NOT NULL DEFAULT '[]',
 created_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT commands_actor_key_pk PRIMARY KEY(actor_user_id,idempotency_key)
);
-- +goose Down
DROP TABLE commands;
DROP TABLE memberships;
DROP TABLE spaces;
DROP TABLE users;
