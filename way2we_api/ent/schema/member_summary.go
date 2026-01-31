package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// MemberSummary holds the schema definition for the MemberSummary entity.
type MemberSummary struct {
	ent.Schema
}

// Fields of the MemberSummary.
func (MemberSummary) Fields() []ent.Field {
	return []ent.Field{
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Int("user_id").
			Comment("Foreign key to User"),
		field.Int("balance").
			Default(0).
			Comment("Current points balance"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Last balance update timestamp"),
	}
}

// Edges of the MemberSummary.
func (MemberSummary) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("group", Group.Type).
			Ref("member_summaries").
			Unique().
			Required().
			Field("group_id").
			Comment("The group of this summary"),
		edge.From("user", User.Type).
			Ref("member_summaries").
			Unique().
			Required().
			Field("user_id").
			Comment("The user of this summary"),
	}
}

// Indexes of the MemberSummary.
func (MemberSummary) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("group_id", "user_id").
			Unique(),
	}
}
