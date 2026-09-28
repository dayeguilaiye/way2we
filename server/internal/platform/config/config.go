package config

import (
	"encoding/hex"
	"fmt"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	AuthSendPerEmail, AuthSendPerSource, AuthVerifyPerSource int
	Environment, HTTPAddr, DatabaseURL, Version              string
	Diagnostics                                              bool
	AuthKey                                                  []byte
	MailpitAddress                                           string
}

func Load() (Config, error) {
	c := Config{Environment: os.Getenv("APP_ENV"), HTTPAddr: os.Getenv("HTTP_ADDR"), DatabaseURL: os.Getenv("DATABASE_URL"), Version: os.Getenv("APP_VERSION")}
	if c.Environment != "local" && c.Environment != "test" && c.Environment != "staging" && c.Environment != "production" {
		return c, fmt.Errorf("APP_ENV must be local, test, staging or production")
	}
	if c.HTTPAddr == "" {
		c.HTTPAddr = "127.0.0.1:8080"
	}
	if c.Version == "" {
		c.Version = "development"
	}
	u, err := url.Parse(c.DatabaseURL)
	if err != nil || u.Host == "" || (u.Scheme != "postgres" && u.Scheme != "postgresql") || u.Path == "" {
		return c, fmt.Errorf("DATABASE_URL must be a PostgreSQL URL")
	}
	if raw := os.Getenv("DEV_DIAGNOSTICS"); raw != "" {
		c.Diagnostics, err = strconv.ParseBool(raw)
		if err != nil {
			return c, fmt.Errorf("DEV_DIAGNOSTICS must be boolean")
		}
	}
	if c.Diagnostics && c.Environment != "local" && c.Environment != "test" {
		return c, fmt.Errorf("diagnostics require local or test environment")
	}

	rawKey, readErr := os.ReadFile(os.Getenv("AUTH_SECRET_FILE"))
	if readErr != nil {
		return c, fmt.Errorf("AUTH_SECRET_FILE must point to a readable local key")
	}
	c.AuthKey, err = hex.DecodeString(strings.TrimSpace(string(rawKey)))
	if err != nil || len(c.AuthKey) != 32 {
		return c, fmt.Errorf("auth secret must be 32 bytes encoded as hex")
	}
	if c.Environment != "local" && c.Environment != "test" {
		return c, fmt.Errorf("configure a production mail sender before deployment")
	}
	c.MailpitAddress = os.Getenv("MAILPIT_SMTP_ADDR")
	if c.MailpitAddress == "" {
		c.MailpitAddress = "127.0.0.1:1025"
	}
	host, _, err := net.SplitHostPort(c.MailpitAddress)
	if err != nil || net.ParseIP(host) == nil || !net.ParseIP(host).IsLoopback() {
		return c, fmt.Errorf("MAILPIT_SMTP_ADDR requires loopback IP")
	}
	for _, setting := range []struct {
		name     string
		value    *int
		fallback int
	}{
		{"AUTH_SEND_PER_EMAIL", &c.AuthSendPerEmail, 5}, {"AUTH_SEND_PER_SOURCE", &c.AuthSendPerSource, 20}, {"AUTH_VERIFY_PER_SOURCE", &c.AuthVerifyPerSource, 60},
	} {
		*setting.value = setting.fallback
		if raw := os.Getenv(setting.name); raw != "" {
			n, e := strconv.Atoi(raw)
			if e != nil || n < 1 || n > 10000 {
				return c, fmt.Errorf("invalid auth rate limit")
			}
			*setting.value = n
		}
	}
	return c, nil
}
