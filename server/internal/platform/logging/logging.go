package logging

import (
	"io"
	"log/slog"
)

func New(w io.Writer, environment, version string) *slog.Logger {
	return slog.New(slog.NewJSONHandler(w, &slog.HandlerOptions{ReplaceAttr: func(_ []string, a slog.Attr) slog.Attr {
		if a.Key == slog.TimeKey {
			return slog.Time(a.Key, a.Value.Time().UTC())
		}
		return a
	}})).With("service", "api", "environment", environment, "version", version)
}
