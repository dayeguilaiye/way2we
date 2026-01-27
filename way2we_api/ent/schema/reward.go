package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// Reward holds the schema definition for the Reward entity.
type Reward struct {
	ent.Schema
}

// Fields of the Reward.
func (Reward) Fields() []ent.Field {
	return []ent.Field{
		field.String("name").
			NotEmpty().
			MaxLen(50).
			Comment("Reward name, 1-50 characters"),
		field.String("description").
			Optional().
			MaxLen(200).
			Comment("Reward description, optional, max 200 characters"),
		field.Int("cost_points").
			Positive().
			Max(99999).
			Comment("Points required for redemption, 1-99999"),
		field.String("cover_image_url").
			Optional().
			Nillable().
			Comment("Optional cover image URL"),
		field.Enum("status").
			Values("active", "inactive").
			Default("active").
			Comment("Reward status: active or inactive"),
		field.Bool("auto_fulfill").
			Default(false).
			Comment("Whether redemption is auto-fulfilled"),
		field.Bool("auto_complete").
			Default(false).
			Comment("Whether redemption auto-completes"),
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Int("provider_id").
			Comment("Foreign key to User who provides this reward"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Reward creation timestamp"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Last update timestamp"),
	}
}

// Edges of the Reward.
func (Reward) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("group", Group.Type).
			Ref("rewards").
			Unique().
			Required().
			Field("group_id").
			Comment("The group this reward belongs to"),
		edge.To("provider", User.Type).
			Unique().
			Required().
			Field("provider_id").
			Comment("The user who provides this reward"),
	}
}

// Indexes of the Reward.
func (Reward) Indexes() []ent.Index {
	return []ent.Index{
		// Index for querying rewards by group
		index.Fields("group_id"),
		// Index for querying rewards by status within a group
		index.Fields("group_id", "status"),
	}
}
