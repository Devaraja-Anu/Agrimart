package api

import (
	"log/slog"
	"net/http"

	"github.com/devaraja-anu/agrilib/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
)

type application struct {
	config config.Config
	logger *slog.Logger
	db     *pgxpool.Pool
}

func NewApplication(cfg config.Config, log *slog.Logger, database *pgxpool.Pool) *application {
	return &application{
		config: cfg,
		logger: log,
		db:     database,
	}
}

func (app *application) Start() error {
	addr := ":" + app.config.Port
	app.logger.Info("server starting", "addr", addr)

	return http.ListenAndServe(addr, app.routes())
}
