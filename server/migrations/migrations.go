package migrations

import (
	"context"
	"database/sql"
	"embed"
	"fmt"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

//go:embed *.sql
var files embed.FS

// Up runs the embedded, versioned migrations explicitly before starting the API.
func Up(ctx context.Context, dsn string) error {
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return fmt.Errorf("open migrations: %w", err)
	}
	defer db.Close()
	p, err := goose.NewProvider(goose.DialectPostgres, db, files)
	if err != nil {
		return fmt.Errorf("create migration provider: %w", err)
	}
	_, err = p.Up(ctx)
	if err != nil {
		return fmt.Errorf("apply migrations: %w", err)
	}
	return nil
}
