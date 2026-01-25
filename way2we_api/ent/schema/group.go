package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
)

// Group holds the schema definition for the Group entity.
type Group struct {
	ent.Schema
}

// Fields of the Group.
func (Group) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").
			NotEmpty().
			MaxLen(30).
			Comment("Group name, 1-30 characters"),
		field.String("description").
			Optional().
			MaxLen(200).
			Comment("Group description, optional, max 200 characters"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Group creation timestamp"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Last update timestamp"),
	}
}

// Edges of the Group.
func (Group) Edges() []ent.Edge {
	return []ent.Edge{
		// Use GroupMember as the through edge to store role
		edge.To("members", GroupMember.Type).
			Comment("Group members with roles"),
	}
}
