package sms

import (
	"context"
	"log/slog"
)

type Sender interface {
	Send(ctx context.Context, phone, message string) error
}

type LogSender struct {
	Logger *slog.Logger
}

func (s *LogSender) Send(ctx context.Context, phone, message string) error {
	s.Logger.Info("dev sms - would have sent SMS", "phone", phone, "message", message)
	return nil
}
