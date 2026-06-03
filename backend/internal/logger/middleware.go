package logger

import (
	"log/slog"
	"net/http"
	"runtime/debug"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

func Middleware(base *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

			start := time.Now()
			requestID := middleware.GetReqID(r.Context())

			reqLogger := base.With(RequestAttrs(
				r.Method,r.URL.Path,requestID,r.RemoteAddr,
			)...)

			ctx := WithContext(r.Context(),reqLogger)

			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

			next.ServeHTTP(ww,r.WithContext(ctx))

			reqLogger.Info("request completed",
			"status",ww.Status(),
			LatencyAttr(start),
			"bytes", ww.BytesWritten(),
		)
		})
	}
}


func Recoverer(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            defer func() {
                if err := recover(); err != nil {

					l := FromContext(r.Context())
                    if l == nil {
                        l = logger
                    }

                    l.Error("panic recovered",
                        "error", err,
                        "path", r.URL.Path,
						"stack", string(debug.Stack()),
                    )
                    http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
                }
            }()
            next.ServeHTTP(w, r)
        })
    }
}