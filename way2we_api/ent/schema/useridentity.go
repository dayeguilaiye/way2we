package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// UserIdentity holds the schema definition for the UserIdentity entity.
// Supports multi-identity authentication: phone, email, wechat, facebook, apple.
type UserIdentity struct {
	ent.Schema
}

// Fields of the UserIdentity.
func (UserIdentity) Fields() []ent.Field {
	return []ent.Field{
		field.Enum("type").
			Values("phone", "email", "wechat", "facebook", "apple").
			Comment("Identity type: phone, email, or social provider"),
		field.String("identifier").
			NotEmpty().
			Comment("The actual identifier: phone number, email address, or OpenID"),
		field.Bool("verified").
			Default(false).
			Comment("Whether this identity has been verified"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("When this identity was created"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("When this identity was last updated"),
	}
}

// Edges of the UserIdentity.
func (UserIdentity) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("user", User.Type).
			Ref("identities").
			Unique().
			Required().
			Comment("The user this identity belongs to"),
	}
}

// Indexes of the UserIdentity.
func (UserIdentity) Indexes() []ent.Index {
	return []ent.Index{
		// Unique constraint: same type + identifier combination must be unique
		index.Fields("type", "identifier").
			Unique(),
	}
}
