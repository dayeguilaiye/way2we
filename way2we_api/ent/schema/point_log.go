package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// PointLog holds the schema definition for the PointLog entity.
type PointLog struct {
	ent.Schema
}

// Fields of the PointLog.
func (PointLog) Fields() []ent.Field {
	return []ent.Field{
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Int("user_id").
			Comment("Foreign key to User"),
		field.Int("delta").
			Comment("Points delta for this change"),
		field.Int("balance_after").
			Comment("Balance after this change"),
		field.String("reason").
			Optional().
			MaxLen(200).
			Comment("Optional reason for the change"),
		field.String("source_type").
			NotEmpty().
			MaxLen(30).
			Comment("Source type for idempotency and tracing"),
		field.String("source_id").
			NotEmpty().
			MaxLen(64).
			Comment("Source identifier for idempotency and tracing"),
		field.Text("source_ref").
			Optional().
			Comment("Original source identifier if source_id is normalized"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Point log creation timestamp"),
	}
}

// Edges of the PointLog.
func (PointLog) Edges() []ent.Edge {
	return []ent.Edge{
		edge.From("group", Group.Type).
			Ref("point_logs").
			Unique().
			Required().
			Field("group_id").
			Comment("The group of this point log"),
		edge.From("user", User.Type).
			Ref("point_logs").
			Unique().
			Required().
			Field("user_id").
			Comment("The user of this point log"),
	}
}

// Indexes of the PointLog.
func (PointLog) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("group_id", "source_type", "source_id").
			Unique(),
		index.Fields("group_id", "user_id", "created_at"),
	}
}
