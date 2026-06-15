package api

import (
	"context"
	"net/http"
)

func (app *application) healthCheck(w http.ResponseWriter, r *http.Request) {

	checkers := map[string]func(context.Context) error{
		"database": app.db.Ping,
		"redis":    func(ctx context.Context) error { return app.redis.Ping(ctx).Err() },
	}

	checks := make(map[string]string, len(checkers))
	allOk := true

	for name, check := range checkers {

		if err := check(r.Context()); err != nil {
			app.logger.Error("healthcheck failed", "dependency", name, "error", err)
			checks[name] = "down"
			allOk = false
			continue
		}
		checks[name] = "ok"
	}

	status := http.StatusOK
	overall := "available"

	if !allOk {
		status = http.StatusServiceUnavailable
		overall = "unavailable"
	}

	writeJSON(w, r, status, envelope{
		Data: map[string]any{
			"status":      overall,
			"environment": string(app.config.AppEnv),
			"checks":      checks,
		},
	})

}
