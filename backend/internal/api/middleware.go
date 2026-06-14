package api

import (
	"net/http"
	"runtime/debug"

	"github.com/devaraja-anu/agrilib/internal/logger"
)

func recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				logger.FromContext(r.Context()).Error("panic recovered",
					"error", err,
					"path", r.URL.Path,
					"stack", string(debug.Stack()),
				)
				writeJSON(w, r, http.StatusInternalServerError, errorEnvelope{
					Error: apiError{Message: "the server encountered an error and could not process your request", Code: ErrCodeInternal},
				})
			}
		}()
		next.ServeHTTP(w, r)
	})
}
