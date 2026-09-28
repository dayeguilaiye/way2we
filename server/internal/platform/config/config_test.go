package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLocalAuthConfiguration(t *testing.T) {
	file := filepath.Join(t.TempDir(), "key")
	if err := os.WriteFile(file, []byte(strings.Repeat("a1", 32)), 0600); err != nil {
		t.Fatal(err)
	}
	for key, value := range map[string]string{"APP_ENV": "local", "DATABASE_URL": "postgres://user:pass@127.0.0.1/test", "AUTH_SECRET_FILE": file, "MAILPIT_SMTP_ADDR": "127.0.0.1:1025", "DEV_DIAGNOSTICS": "false", "AUTH_SEND_PER_EMAIL": "5", "AUTH_SEND_PER_SOURCE": "20", "AUTH_VERIFY_PER_SOURCE": "60"} {
		t.Setenv(key, value)
	}
	if cfg, err := Load(); err != nil || len(cfg.AuthKey) != 32 || cfg.AuthSendPerEmail != 5 {
		t.Fatalf("local config: %v", err)
	}
	t.Setenv("MAILPIT_SMTP_ADDR", "smtp.example.com:25")
	if _, err := Load(); err == nil {
		t.Fatal("local sender allowed external SMTP")
	}
	t.Setenv("MAILPIT_SMTP_ADDR", "127.0.0.1:1025")
	t.Setenv("APP_ENV", "production")
	if _, err := Load(); err == nil {
		t.Fatal("production started with local email adapter")
	}
}
