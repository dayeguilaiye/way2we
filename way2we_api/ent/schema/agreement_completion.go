package schema

import (
	"time"

	"entgo.io/ent"
	"entgo.io/ent/schema/edge"
	"entgo.io/ent/schema/field"
	"entgo.io/ent/schema/index"
)

// AgreementCompletion holds the schema definition for the AgreementCompletion entity.
type AgreementCompletion struct {
	ent.Schema
}

// Fields of the AgreementCompletion.
func (AgreementCompletion) Fields() []ent.Field {
	return []ent.Field{
		field.Int("group_id").
			Comment("Foreign key to Group"),
		field.Int("agreement_id").
			Comment("Foreign key to Agreement"),
		field.Int("completer_id").
			Comment("User who completed the agreement"),
		field.Int("recorder_id").
			Comment("User who recorded the completion"),
		field.Int("points").
			Comment("Snapshot of agreement points"),
		field.Bool("require_confirmation").
			Default(true).
			Comment("Snapshot of agreement require_confirmation"),
		field.Enum("status").
			Values("pending", "confirmed", "rejected").
			Default("pending").
			Comment("Completion status"),
		field.String("rejected_reason").
			Optional().
			MaxLen(200).
			Comment("Optional rejection reason"),
		field.Int("confirmed_by").
			Optional().
			Nillable().
			Comment("User who confirmed the completion"),
		field.Time("confirmed_at").
			Optional().
			Nillable().
			Comment("Confirmation timestamp"),
		field.Time("rejected_at").
			Optional().
			Nillable().
			Comment("Rejection timestamp"),
		field.Time("created_at").
			Default(time.Now).
			Immutable().
			Comment("Completion creation timestamp"),
		field.Time("updated_at").
			Default(time.Now).
			UpdateDefault(time.Now).
			Comment("Completion update timestamp"),
	}
}

// Edges of the AgreementCompletion.
func (AgreementCompletion) Edges() []ent.Edge {
	return []ent.Edge{
		edge.To("group", Group.Type).
			Unique().
			Required().
			Field("group_id").
			Comment("The group this completion belongs to"),
		edge.To("agreement", Agreement.Type).
			Unique().
			Required().
			Field("agreement_id").
			Comment("The agreement this completion belongs to"),
		edge.To("completer", User.Type).
			Unique().
			Required().
			Field("completer_id").
			Comment("The user who completed the agreement"),
		edge.To("recorder", User.Type).
			Unique().
			Required().
			Field("recorder_id").
			Comment("The user who recorded the completion"),
		edge.To("confirmer", User.Type).
			Unique().
			Field("confirmed_by").
			Comment("The user who confirmed the completion"),
	}
}

// Indexes of the AgreementCompletion.
func (AgreementCompletion) Indexes() []ent.Index {
	return []ent.Index{
		index.Fields("group_id", "status", "created_at"),
		index.Fields("group_id", "completer_id", "created_at"),
	}
}
