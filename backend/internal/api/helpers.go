package api

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/devaraja-anu/agrilib/internal/logger"
	"github.com/go-chi/chi/v5"
)

const (
	defaultPageSize = 20
	maxPageSize     = 100
)

const maxBodyBytes = 1_048_576 // 1MB

func readJSON(r *http.Request, dst any) error {

	r.Body = http.MaxBytesReader(nil, r.Body, maxBodyBytes)

	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()

	if err := dec.Decode(dst); err != nil {
		var (
			syntaxErr        *json.SyntaxError
			unmarshalTypeErr *json.UnmarshalTypeError
			invalidUnmarshal *json.InvalidUnmarshalError
		)

		switch {
		case errors.As(err, &syntaxErr):
			return fmt.Errorf("malformed json at character %d", syntaxErr.Offset)
		case errors.Is(err, io.ErrUnexpectedEOF):
			return errors.New("malformed json: unexpected end of Input")
		case errors.As(err, &unmarshalTypeErr):
			if unmarshalTypeErr.Field != "" {
				return fmt.Errorf("incorrect type for field %q", unmarshalTypeErr.Field)
			}
			return fmt.Errorf("incorrect type at character %d", unmarshalTypeErr.Offset)
		case errors.Is(err, io.EOF):
			return errors.New("request body must not be empty")

		case strings.HasPrefix(err.Error(), "json: unknown field"):
			field := strings.TrimPrefix(err.Error(), "json: unknown field")
			return fmt.Errorf("unknown field %s", field)
		case err.Error() == "http: request body too large":
			return fmt.Errorf("request body must not exceed 1 MB")
		case errors.As(err, &invalidUnmarshal):
			panic(fmt.Sprintf("readJSON: invalid unmarshal target: %v", err))
		default:
			return err
		}

	}

	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("request body must contain only one JSON value")
	}

	return nil
}

func writeJSON(w http.ResponseWriter, r *http.Request, status int, val any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(val); err != nil {
		logger.FromContext(r.Context()).Error("failed to encode json response", "error", err)
	}
}

func urlParam(r *http.Request, key string) string {
	return chi.URLParam(r, key)
}

func queryString(r *http.Request, key, fallback string) string {
	v := r.URL.Query().Get(key)
	if v == "" {
		return fallback
	}
	return v
}

func queryCSV(r *http.Request, key string) []string {

	v := r.URL.Query().Get(key)
	if v == "" {
		return nil
	}

	parts := strings.Split(v, ",")
	output := make([]string, 0, len(parts))

	for _, p := range parts {
		if t := strings.TrimSpace(p); t != "" {
			output = append(output, t)
		}
	}

	return output
}

// for optional parameters
func QueryInt(r *http.Request, key string, fallback int) int {

	v := r.URL.Query().Get(key)
	if v == "" {
		return fallback
	}

	n, err := strconv.Atoi(v)
	if err != nil {
		return fallback
	}

	return n
}

// for strictly required parameters
func strictQueryInt(r *http.Request, key string) (int, error) {

	v := r.URL.Query().Get(key)
	if v == "" {
		return 0, fmt.Errorf("missing required query parameter: %q", key)
	}

	n, err := strconv.Atoi(v)
	if err != nil {
		return 0, fmt.Errorf("query parameter %q must be an integer", key)
	}

	return n, nil
}

func pageParams(r *http.Request) (int, int) {

	size := QueryInt(r, "page_size", defaultPageSize)
	page := QueryInt(r, "page", 1)

	if size < 1 {
		size = defaultPageSize
	}

	if size > maxPageSize {
		size = maxPageSize
	}

	if page < 1 {
		size = 1
	}

	offset := (page - 1) * size
	return size, offset
}

//-----------------------------------------
// Pagination
//-----------------------------------------

type paginatedResponse struct {
	Data       any   `json:"data"`
	Total      int64 `json:"total"`
	PageSize   int   `json:"page_size"`
	PageOffset int   `json:"page_offset"`
}

func paginate(w http.ResponseWriter, r *http.Request, data any, total int64, pageSize, offset int) {
	writeJSON(w, r, http.StatusOK, paginatedResponse{
		Data:       data,
		Total:      total,
		PageSize:   pageSize,
		PageOffset: offset,
	})
}
