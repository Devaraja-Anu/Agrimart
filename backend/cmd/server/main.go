package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/devaraja-anu/agrilib/internal/api"
	"github.com/devaraja-anu/agrilib/internal/config"
	"github.com/devaraja-anu/agrilib/internal/db"
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

	ctx := context.Background()

	pool,err := db.NewPool(ctx,cfg.DatabaseURL)
	if err != nil {
		slog.Error("Unable to intialize DB","error",err)
		os.Exit(1)
	}
	
	defer pool.Close()

	app := api.NewApplication(cfg, loggerInstance,pool)

	if err := app.Start(); err != nil {
		slog.Error("Server Error", "error", err)
		os.Exit(1)
	}

}
