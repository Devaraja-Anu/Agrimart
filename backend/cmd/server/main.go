package main

import (
	"log/slog"
	"os"

	"github.com/devaraja-anu/agrilib/internal/api"
	"github.com/devaraja-anu/agrilib/internal/config"
	"github.com/devaraja-anu/agrilib/internal/logger"
)

func main() {

	cfg, err := config.Load()
	if err != nil {
		slog.Error("invalid configuration", "error", err)
		os.Exit(1)
	}

	loggerInstance := logger.New()
	slog.SetDefault(loggerInstance)

	app := api.NewApplication(cfg, loggerInstance, nil)

	if err := app.Start(); err != nil {
		slog.Error("Server Error", "error", err)
		os.Exit(1)
	}

}
