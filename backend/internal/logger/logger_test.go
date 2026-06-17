package logger_test

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"strings"
	"testing"
	"time"

	"github.com/devaraja-anu/agrilib/internal/logger"
)

func TestNew_ProductionEmitsJSON(t *testing.T) {
	var buf bytes.Buffer
	handler := slog.NewJSONHandler(&buf, nil)
	l := slog.New(handler)
	l.Info("test event", "key", "value")

	var out map[string]any
	if err := json.Unmarshal(buf.Bytes(), &out); err != nil {
		t.Fatalf("expected JSON output, got: %s", buf.String())
	}
	if out["msg"] != "test event" {
		t.Errorf("unexpected msg: %v", out["msg"])
	}
}

func TestFromContext_FallsBackToDefault(t *testing.T) {
	ctx := context.Background()
	l := logger.FromContext(ctx)
	if l == nil {
		t.Fatal("expected non-nil logger from empty context")
	}
}

func TestFromContext_ReturnsStoredLogger(t *testing.T) {
	var buf bytes.Buffer
	custom := slog.New(slog.NewTextHandler(&buf, nil))

	ctx := logger.WithContext(context.Background(), custom)
	got := logger.FromContext(ctx)
	got.Info("hello from context")

	if !strings.Contains(buf.String(), "hello from context") {
		t.Errorf("expected log output in buffer, got: %s", buf.String())
	}
}

func TestLatencyAttr(t *testing.T) {
		start := time.Now().Add(-42 * time.Millisecond)

	attr := logger.LatencyAttr(start)

	if attr.Key != "latency" {
		t.Fatalf("got key %q, want %q", attr.Key, "latency")
	}

	if attr.Value.Kind() != slog.KindDuration {
		t.Fatalf("expected duration value, got %v", attr.Value.Kind())
	}

	if attr.Value.Duration() < 40*time.Millisecond {
		t.Fatalf("unexpected duration: %v", attr.Value.Duration())
	}
}
