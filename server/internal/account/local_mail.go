package account

import (
	"context"
	"fmt"
	"mime"
	"net"
	"net/smtp"
	"strings"
	"time"
)

// LocalMailpit sends only to a loopback test inbox; it never relays external mail.
// The production sender is selected when the sending service is configured.
type LocalMailpit struct{ Address string }

func (m LocalMailpit) SendCode(ctx context.Context, message CodeMail) error {
	host, _, err := net.SplitHostPort(m.Address)
	if err != nil {
		return fmt.Errorf("invalid local mail address")
	}
	ip := net.ParseIP(host)
	if ip == nil || !ip.IsLoopback() {
		return fmt.Errorf("local mail requires loopback IP")
	}
	connection, err := (&net.Dialer{Timeout: 5 * time.Second}).DialContext(ctx, "tcp", m.Address)
	if err != nil {
		return fmt.Errorf("connect local inbox: %w", err)
	}
	defer connection.Close()
	deadline := time.Now().Add(8 * time.Second)
	if value, ok := ctx.Deadline(); ok && value.Before(deadline) {
		deadline = value
	}
	if err = connection.SetDeadline(deadline); err != nil {
		return err
	}
	stop := context.AfterFunc(ctx, func() { _ = connection.Close() })
	defer stop()
	client, err := smtp.NewClient(connection, host)
	if err != nil {
		return err
	}
	defer client.Close()
	if err = client.Mail("no-reply@way2we.test"); err != nil {
		return err
	}
	if err = client.Rcpt(message.Email); err != nil {
		return err
	}
	writer, err := client.Data()
	if err != nil {
		return err
	}
	headers := []string{"From: Way2We <no-reply@way2we.test>", "To: " + message.Email, "Subject: " + mime.QEncoding.Encode("UTF-8", "一起的小日子 · 登录验证码"), "Message-ID: <" + message.ID + "@way2we.test>", "Date: " + time.Now().UTC().Format(time.RFC1123Z), "MIME-Version: 1.0", "Content-Type: text/plain; charset=UTF-8", "Content-Transfer-Encoding: 8bit", "", "你的登录验证码是：" + message.Code, "", "验证码在申请后 10 分钟内有效。请勿将验证码分享给他人。", "如果不是你发起的登录，请忽略这封邮件。", ""}
	if _, err = writer.Write([]byte(strings.Join(headers, "\r\n"))); err != nil {
		return err
	}
	if err = writer.Close(); err != nil {
		return err
	}
	return client.Quit()
}
