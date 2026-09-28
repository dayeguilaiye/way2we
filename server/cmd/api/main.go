package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"way2we/server/internal/account"
	"way2we/server/internal/httpapi"
	"way2we/server/internal/platform/config"
	"way2we/server/internal/platform/database"
	"way2we/server/internal/platform/logging"
)

func main() { os.Exit(run()) }
func run() int {
	logger := logging.New(os.Stdout, os.Getenv("APP_ENV"), os.Getenv("APP_VERSION"))
	cfg, err := config.Load()
	if err != nil {
		logger.Error("configuration invalid", "event", "configuration_invalid")
		return 1
	}
	logger = logging.New(os.Stdout, cfg.Environment, cfg.Version)
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	connectCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	pool, err := database.Open(connectCtx, cfg.DatabaseURL)
	cancel()
	if err != nil {
		logger.Error("database unavailable", "event", "startup_failed", "error_kind", "database")
		return 1
	}
	defer pool.Close()
	accounts, err := account.NewWithLimits(pool, cfg.AuthKey, account.LocalMailpit{Address: cfg.MailpitAddress}, account.Limits{SendPerEmail: cfg.AuthSendPerEmail, SendPerSource: cfg.AuthSendPerSource, VerifyPerSource: cfg.AuthVerifyPerSource})
	if err != nil {
		logger.Error("account configuration invalid", "event", "startup_failed")
		return 1
	}
	workerCtx, workerCancel := context.WithCancel(context.Background())
	workerDone := make(chan struct{})
	go func() { defer close(workerDone); accounts.RunDelivery(workerCtx, logger) }()
	defer func() { workerCancel(); <-workerDone }()
	server := &http.Server{Addr: cfg.HTTPAddr, Handler: httpapi.New(logger, pool.Ping, cfg.Diagnostics, accounts), ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second, WriteTimeout: 20 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 16384}
	failed := make(chan error, 1)
	go func() { failed <- server.ListenAndServe() }()
	logger.Info("server starting", "event", "server_starting")
	select {
	case err = <-failed:
		if !errors.Is(err, http.ErrServerClosed) {
			logger.Error("listener failed", "event", "startup_failed")
			return 1
		}
	case <-ctx.Done():
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer shutdownCancel()
		if err = server.Shutdown(shutdownCtx); err != nil {
			logger.Error("shutdown deadline reached", "event", "shutdown_failed")
			_ = server.Close()
			return 1
		}
		<-failed
	}
	logger.Info("server stopped", "event", "server_stopped")
	return 0
}
