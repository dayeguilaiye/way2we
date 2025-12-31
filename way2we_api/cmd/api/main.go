package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	_ "github.com/lib/pq"
	"github.com/way2we/way2we_api/ent"
	"github.com/way2we/way2we_api/internal/pkg/config"
)

func main() {
	// Load configuration
	cfg := config.MustLoadConfig()

	// Initialize Ent client
	client, err := ent.Open(cfg.Database.Driver, cfg.Database.Source)
	if err != nil {
		log.Fatalf("failed opening connection to postgres: %v", err)
	}
	defer client.Close()

	// Run migration
	if err := client.Schema.Create(context.Background()); err != nil {
		log.Fatalf("failed creating schema resources: %v", err)
	}

	// Initialize Echo
	e := echo.New()

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// Routes
	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Welcome to Way2We API!")
	})

	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "UP"})
	})

	// Start server
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	e.Logger.Fatal(e.Start(addr))
}
