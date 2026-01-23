// Package auth provides authentication adapter implementations.
package auth

import (
	"context"
	"log/slog"
)

// LogSmsProvider is a mock SMS provider that logs verification codes to stdout.
// This implementation is intended for MVP/development use only.
type LogSmsProvider struct{}

// NewLogSmsProvider creates a new LogSmsProvider instance.
func NewLogSmsProvider() *LogSmsProvider {
	return &LogSmsProvider{}
}

// Send logs the SMS verification code instead of actually sending it.
// In production, this should be replaced with a real SMS provider.
func (p *LogSmsProvider) Send(ctx context.Context, phone string, code string) error {
	slog.Info("verification code sent",
		"provider", "sms_mock",
		"phone", phone,
		"code", code,
	)
	return nil
}

// LogEmailProvider is a mock email provider that logs verification codes to stdout.
// This implementation is intended for MVP/development use only.
type LogEmailProvider struct{}

// NewLogEmailProvider creates a new LogEmailProvider instance.
func NewLogEmailProvider() *LogEmailProvider {
	return &LogEmailProvider{}
}

// Send logs the email verification code instead of actually sending it.
// In production, this should be replaced with a real email provider.
func (p *LogEmailProvider) Send(ctx context.Context, email string, code string) error {
	slog.Info("verification code sent",
		"provider", "email_mock",
		"email", email,
		"code", code,
	)
	return nil
}
