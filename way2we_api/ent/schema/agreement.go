package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// Agreement holds the schema definition for the Agreement entity.
type Agreement struct {
	ent.Schema
}

// Fields of the Agreement.
func (Agreement) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").
			NotEmpty().
			MaxLen(50).
			Comment("Agreement name, 1-50 characters"),
		field.String("description").
			Optional().
			MaxLen(200).
			Comment("Agreement description, optional, max 200 characters"),
		field.Int("points").
			Positive().
			Max(99999).
			Comment("Points for completing this agreement, 1-99999"),
		field.Bool("require_confirmation").
			Default(true).
			Comment("Whether completion requires confirmation"),
		field.String("cover_image_url").
			Optional().
			Nillable().
			Comment("Optional cover image URL"),
		field.Enum("status").
			Values("active", "inactive").
			Default("active").
			Comment("Agreement status: active or inactive"),
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Int("creator_id").
			Comment("Foreign key to User who created this agreement"),
		field.JSON("applicable_member_ids", []int{}).
			Optional().
			Comment("List of member IDs this agreement applies to, empty means all members"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Agreement creation timestamp"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Last update timestamp"),
	}
}

// Edges of the Agreement.
func (Agreement) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("group", Group.Type).
			Ref("agreements").
			Unique().
			Required().
			Field("group_id").
			Comment("The group this agreement belongs to"),
		edge.To("creator", User.Type).
			Unique().
			Required().
			Field("creator_id").
			Comment("The user who created this agreement"),
		edge.From("pinned_by_users", User.Type).
			Ref("pinned_agreements").
			Comment("Users who pinned this agreement"),
	}
}

// Indexes of the Agreement.
func (Agreement) Indexes() []ent.Index {
	return []ent.Index{
		// Index for querying agreements by group
		index.Fields("group_id"),
		// Index for querying agreements by status within a group
		index.Fields("group_id", "status"),
	}
}
