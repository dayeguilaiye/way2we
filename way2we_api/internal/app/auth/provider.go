// Package auth provides authentication and verification services.
package auth

import "context"

// SmsProvider defines the interface for sending SMS verification codes.
// Implementations may be mock (logging), Aliyun, Tencent Cloud, Twilio, etc.
type SmsProvider interface {
	// Send sends a verification code to the specified phone number.
	// Returns an error if the SMS could not be sent.
	Send(ctx context.Context, phone string, code string) error
}

// EmailProvider defines the interface for sending email verification codes.
// Implementations may be mock (logging), SMTP, SendGrid, etc.
type EmailProvider interface {
	// Send sends a verification code to the specified email address.
	// Returns an error if the email could not be sent.
	Send(ctx context.Context, email string, code string) error
}
