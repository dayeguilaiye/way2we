package schema

import (
	"entgo.io/ent"
	"entgo.io/ent/schema/field"
)

// User holds the schema definition for the User entity.
type User struct {
	ent.Schema
}

// Fields of the User.
func (User) Fields() []ent.Field {
	return []ent.Field{
		field.String("email").
			Optional().
			Unique(),
		field.String("phone").
			Optional().
			Unique(),
		field.String("password_hash").
			NotEmpty().
			Sensitive(), // Sensitive prevents it from being printed in logs
		field.String("nickname").
			Optional(),
	}
}

// Edges of the User.
func (User) Edges() []ent.Edge {
	return nil
}
