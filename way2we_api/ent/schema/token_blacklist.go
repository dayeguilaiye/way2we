package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

// TokenBlacklist holds the schema definition for the TokenBlacklist entity.
type TokenBlacklist struct {
	ent.Schema
}

// Fields of the TokenBlacklist.
func (TokenBlacklist) Fields() []ent.Field {
	return []ent.Field{
		field.String("token_hash").
			NotEmpty().
			Unique().
			Comment("SHA256 hash of the invalidated JWT token"),
		field.Time("expires_at").
			Comment("Token expiration time - can be safely deleted after this"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("When the token was blacklisted"),
	}
}

// Edges of the TokenBlacklist.
func (TokenBlacklist) Edges() []ent.Edge {
	return nil
}
