package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/devaraja-anu/agrilib/internal/config"
	"github.com/devaraja-anu/agrilib/internal/db"
	"github.com/devaraja-anu/agrilib/internal/sms"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type application struct {
	config    config.Config
	logger    *slog.Logger
	db        *pgxpool.Pool
	queries   *db.Queries
	redis     *redis.Client
	wg        sync.WaitGroup
	smsSender *sms.LogSender
}

func NewApplication(cfg config.Config, log *slog.Logger, database *pgxpool.Pool, 
	redisClient *redis.Client, smsSender *sms.LogSender,queries *db.Queries) *application {
	return &application{
		config:    cfg,
		logger:    log,
		db:        database,
		redis:     redisClient,
		smsSender: smsSender,
	}
}

func (app *application) Serve() error {

	srv := &http.Server{
		Addr:              fmt.Sprintf(":%s", app.config.Port),
		Handler:           app.routes(),
		ReadTimeout:       5 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
		ReadHeaderTimeout: 2 * time.Second,
	}

	shutdownError := make(chan error, 1)

	go func() {

		quit := make(chan os.Signal, 1)
		signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
		defer signal.Stop(quit)
		s := <-quit

		app.logger.Info("shutting down server", "signal", s.String())

		ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer cancel()

		err := srv.Shutdown(ctx)
		if err != nil {
			shutdownError <- err
		}

		app.logger.Info("completing background tasks", "address", srv.Addr)
		app.wg.Wait()
		shutdownError <- nil
	}()

	app.logger.Info("starting server", "addr", srv.Addr)

	if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
		return err
	}

	if err := <-shutdownError; err != nil {
		return err
	}

	app.logger.Info("server stopped", "addr", srv.Addr)
	return nil
}

func (app *application) backgroundFn(fn func()) {
	app.wg.Add(1)

	go func() {
		defer app.wg.Done()

		defer func() {
			err := recover()
			if err != nil {
				app.logger.Error("background task panicked", "error", fmt.Errorf("%v", err))
			}
		}()

		fn()
	}()
}
