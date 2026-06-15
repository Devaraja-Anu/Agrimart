package main

import (
	"context"
	"log/slog"
	"os"

	"github.com/devaraja-anu/agrilib/internal/api"
	"github.com/devaraja-anu/agrilib/internal/config"
	"github.com/devaraja-anu/agrilib/internal/db/database"
	"github.com/devaraja-anu/agrilib/internal/logger"
	"github.com/devaraja-anu/agrilib/internal/redis"
)

func main() {

	loggerInstance := logger.New()
	slog.SetDefault(loggerInstance)

	cfg, err := config.Load()
	if err != nil {
		slog.Error("invalid configuration", "error", err)
		os.Exit(1)
	}

	ctx := context.Background()

	pool, err := database.NewPool(ctx, cfg.DatabaseURL.Reveal())
	if err != nil {
		slog.Error("Unable to intialize DB", "error", err)
		os.Exit(1)
	}

	defer pool.Close()

	redisClient, err := redis.NewClient(ctx, cfg.RedisURL.Reveal())
	if err != nil {
		slog.Error("Unable to intialize Redis", "error", err)
		os.Exit(1)
	}

	defer redisClient.Close()

	app := api.NewApplication(cfg, loggerInstance, pool, redisClient)

	if err := app.Serve(); err != nil {
		slog.Error("Server Error", "error", err)
		os.Exit(1)
	}

}
