package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

// User holds the schema definition for the User entity.
type User struct {
	ent.Schema
}

// Fields of the User.
func (User) Fields() []ent.Field {
	return []ent.Field{
		field.String("nickname").
			Optional().
			MaxLen(20).
			Comment("Display name, 1-20 characters"),
		field.String("avatar").
			Optional().
			Comment("Avatar image URL"),
		field.String("password_hash").
			NotEmpty().
			Sensitive(). // Prevents it from being printed in logs
			Comment("bcrypt hashed password"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Account creation timestamp"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Last profile update timestamp"),
	}
}

// Edges of the User.
func (User) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("identities", UserIdentity.Type).
			Comment("Login identities (phone, email, social)"),
		edge.From("group_memberships", GroupMember.Type).
			Ref("user").
			Comment("Groups this user is a member of"),
		edge.To("pinned_agreements", Agreement.Type).
			Comment("Agreements pinned by this user"),
		edge.To("pinned_rewards", Reward.Type).
			Comment("Rewards pinned by this user"),
	}
}
