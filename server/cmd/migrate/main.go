package main

import (
	"context"
	"os"
	"time"

	"way2we/server/internal/platform/config"
	"way2we/server/internal/platform/logging"
	"way2we/server/migrations"
)

func main() {
	logger := logging.New(os.Stdout, os.Getenv("APP_ENV"), os.Getenv("APP_VERSION"))
	cfg, err := config.Load()
	if err != nil {
		logger.Error("configuration invalid", "event", "configuration_invalid")
		os.Exit(1)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	if err = migrations.Up(ctx, cfg.DatabaseURL); err != nil {
		logger.Error("migration failed", "event", "migration_failed")
		os.Exit(1)
	}
	logger.Info("migrations applied", "event", "migrations_applied")
}
