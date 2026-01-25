package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// GroupMember holds the schema definition for the GroupMember entity.
// This is an edge schema that connects User and Group with additional fields.
type GroupMember struct {
	ent.Schema
}

// Fields of the GroupMember.
func (GroupMember) Fields() []ent.Field {
	return []ent.Field{
		field.Int("user_id").
			Comment("Foreign key to User"),
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Enum("role").
			Values("admin", "member").
			Default("member").
			Comment("Member role in the group"),
		field.Time("joined_at").
			Default(time.Now).
			Immutable().
			Comment("When the user joined the group"),
	}
}

// Edges of the GroupMember.
func (GroupMember) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("user", User.Type).
			Unique().
			Required().
			Field("user_id").
			Comment("The user in this membership"),
		edge.From("group", Group.Type).
			Ref("members").
			Unique().
			Required().
			Field("group_id").
			Comment("The group of this membership"),
	}
}

// Indexes of the GroupMember.
func (GroupMember) Indexes() []ent.Index {
	return []ent.Index{
		// Ensure a user can only be a member of a group once
		index.Fields("user_id", "group_id").
			Unique(),
	}
}
