package config

import (
	"fmt"
	"net/url"
	"os"
	"strconv"
)

type Config struct {
	Environment, HTTPAddr, DatabaseURL, Version string
	Diagnostics                                 bool
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
	return c, nil
}
