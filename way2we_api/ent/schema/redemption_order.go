package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// RedemptionOrder holds the schema definition for the RedemptionOrder entity.
type RedemptionOrder struct {
	ent.Schema
}

// Fields of the RedemptionOrder.
func (RedemptionOrder) Fields() []ent.Field {
	return []ent.Field{
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Int("reward_id").
			Comment("Foreign key to Reward"),
		field.Int("consumer_id").
			Comment("User who created the order"),
		field.Int("provider_id").
			Comment("Snapshot of reward provider_id"),
		field.Int("quantity").
			Positive().
			Comment("Order quantity, minimum 1"),
		field.Int("unit_cost_points").
			Positive().
			Comment("Snapshot of reward cost_points"),
		field.Int("total_cost_points").
			Positive().
			Comment("Total points cost (unit * quantity)"),
		field.Enum("status").
			Values("awaiting_fulfill", "awaiting_confirm", "completed", "unsatisfied").
			Default("awaiting_fulfill").
			Comment("Order status"),
		field.Bool("auto_fulfill").
			Default(false).
			Comment("Snapshot of reward auto_fulfill"),
		field.Bool("auto_complete").
			Default(false).
			Comment("Snapshot of reward auto_complete"),
		field.Int("provider_incentive_ratio").
			Default(0).
			Min(0).
			Max(100).
			Comment("Snapshot of group provider incentive ratio (0-100)"),
		field.Time("fulfilled_at").
			Optional().
			Nillable().
			Comment("Fulfillment timestamp"),
		field.Time("confirmed_at").
			Optional().
			Nillable().
			Comment("Confirmation timestamp"),
		field.Time("ended_at").
			Optional().
			Nillable().
			Comment("Unsatisfied end timestamp"),
		field.String("unsatisfied_reason").
			Optional().
			MaxLen(200).
			Comment("Optional unsatisfied reason (max 200 chars)"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Order creation timestamp"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Order update timestamp"),
	}
}

// Edges of the RedemptionOrder.
func (RedemptionOrder) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("group", Group.Type).
			Unique().
			Required().
			Field("group_id").
			Comment("The group this order belongs to"),
		edge.To("reward", Reward.Type).
			Unique().
			Required().
			Field("reward_id").
			Comment("The reward this order is for"),
		edge.To("consumer", User.Type).
			Unique().
			Required().
			Field("consumer_id").
			Comment("The user who created the order"),
		edge.To("provider", User.Type).
			Unique().
			Required().
			Field("provider_id").
			Comment("The user who provides the reward"),
	}
}

// Indexes of the RedemptionOrder.
func (RedemptionOrder) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("group_id", "consumer_id", "created_at"),
		index.Fields("group_id", "provider_id", "created_at"),
		index.Fields("group_id", "status", "created_at"),
	}
}
