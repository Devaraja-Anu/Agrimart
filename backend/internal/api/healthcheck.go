package api

import "net/http"

func (app *application)  healthCheck(w http.ResponseWriter, r *http.Request) {
	if err := app.db.Ping(r.Context()); err != nil {
		app.logger.Error("healthcheck: database ping failed", "error",err)
		writeJSON(w,r,http.StatusServiceUnavailable,envelope{
			Data: map[string]any{
				"status":"unavailable",
				"checks":map[string]string{
					"database":"down",
				},
			},
		})
		return
	}

	ok(w,r,map[string]any{
		"status":"available",
		"environment":app.config.AppEnv,
		"checks":map[string]string{
					"database":"ok",
				},
	})

}
