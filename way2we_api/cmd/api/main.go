package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	_ "github.com/lib/pq"
	"github.com/way2we/way2we_api/ent"
	adapterAuth "github.com/way2we/way2we_api/internal/adapter/auth"
	"github.com/way2we/way2we_api/internal/adapter/handler"
	"github.com/way2we/way2we_api/internal/app/auth"
	"github.com/way2we/way2we_api/internal/pkg/config"
)

func main() {
	// Initialize slog with JSON handler for production-ready logging
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
	slog.SetDefault(logger)

	// Load configuration
	cfg := config.MustLoadConfig()

	// Initialize Ent client
	client, err := ent.Open(cfg.Database.Driver, cfg.Database.Source)
	if err != nil {
		slog.Error("failed opening connection to postgres", "error", err)
		os.Exit(1)
	}
	defer client.Close()

	// Run migration
	if err := client.Schema.Create(context.Background()); err != nil {
		slog.Error("failed creating schema resources", "error", err)
		os.Exit(1)
	}

	slog.Info("database migration completed successfully")

	// Initialize auth providers (Mock for MVP)
	smsProvider := adapterAuth.NewLogSmsProvider()
	emailProvider := adapterAuth.NewLogEmailProvider()

	// Initialize auth service
	authService := auth.NewService(client, smsProvider, emailProvider)

	// Initialize Echo
	e := echo.New()
	e.HideBanner = true

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: cfg.Server.AllowOrigins,
		AllowMethods: []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete, http.MethodOptions},
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
	}))

	// Register auth routes
	authHandler := handler.NewAuthHandler(authService)
	authHandler.RegisterRoutes(e)

	// Routes
	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Welcome to Way2We API!")
	})

	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "UP"})
	})

	// Start server
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	slog.Info("starting server", "addr", addr)
	e.Logger.Fatal(e.Start(addr))
}
