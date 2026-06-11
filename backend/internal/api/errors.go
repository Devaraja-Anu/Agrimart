package api

import (
	"net/http"

	"github.com/devaraja-anu/agrilib/internal/logger"
)

const (
	ErrCodeNotFound     = "not_found"
	ErrCodeUnauthorized = "unauthorized"
	ErrCodeForbidden    = "forbidden"
	ErrCodeBadRequest   = "bad_request"
	ErrCodeConflict     = "conflict"
	ErrCodeValidation   = "validation_error"
	ErrCodeInternal     = "internal_error"
	ErrCodeRateLimited  = "rate_limited"
)

type apiError struct {
	Message string `json:"message"`
	Code    string `json:"code"` // machine-readable, e.g. "listing_not_found"
}

type errorEnvelope struct {
	Error apiError `json:"error"`
}

func badRequest(w http.ResponseWriter, r *http.Request, err error) {
	writeJSON(w, r, http.StatusBadRequest, errorEnvelope{ Error:apiError{Message: err.Error(), Code: ErrCodeBadRequest}})
}

func validationError(w http.ResponseWriter, r *http.Request, err error) {
	writeJSON(w, r, http.StatusUnprocessableEntity, errorEnvelope{
		Error: apiError{Message: err.Error(), Code: ErrCodeValidation},
	})
}

func unauthorized(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, r, http.StatusUnauthorized, errorEnvelope{
		Error: apiError{Message: "unauthorized", Code: ErrCodeUnauthorized},
	})
}

func forbidden(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, r, http.StatusForbidden, errorEnvelope{
		Error: apiError{Message: "forbidden", Code: ErrCodeForbidden},
	})
}

func notFound(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, r, http.StatusNotFound, errorEnvelope{
		Error: apiError{Message: "the requested resource could not be found", Code: ErrCodeNotFound},
	})
}

func conflict(w http.ResponseWriter, r *http.Request, err error) {
	writeJSON(w, r, http.StatusConflict, errorEnvelope{
		Error: apiError{Message: err.Error(), Code: ErrCodeConflict},
	})
}

func rateLimited(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, r, http.StatusTooManyRequests, errorEnvelope{
		Error: apiError{Message: "too many requests", Code: ErrCodeRateLimited},
	})
}

func serverError(w http.ResponseWriter, r *http.Request, err error) {
	logger.FromContext(r.Context()).Error("internal server error", "error", err)
	writeJSON(w, r, http.StatusInternalServerError, errorEnvelope{
		Error: apiError{Message: "the server encountered an error and could not process your request", Code: ErrCodeInternal},
	})
}
