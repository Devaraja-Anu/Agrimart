package api

import "net/http"

type envelope struct {
	Data any   `json:"data"`
	Meta *meta `json:"meta,omitempty"` // only present on collection responses
}

type meta struct {
	Total      int64 `json:"total"` // total records matching the query
	PageSize   int   `json:"page_size"`
	PageOffset int   `json:"offset"`
	PageCount  int   `json:"page_count"` // total number of pages
}


func ok(w http.ResponseWriter, r *http.Request, data any) {
	writeJSON(w, r, http.StatusOK, envelope{Data: data})
}

func created(w http.ResponseWriter, r *http.Request, data any) {
	writeJSON(w, r, http.StatusCreated, envelope{Data: data})
}

func noContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}

func collection(w http.ResponseWriter, r *http.Request, data any, total int64, pageSize, offset int) {
	pageCount := 0
	if pageSize > 0 {
		pageCount = int((total + int64(pageSize) - 1) / int64(pageSize))
	}

	writeJSON(w, r, http.StatusOK, envelope{
		Data: data,
		Meta: &meta{
			Total:      total,
			PageSize:   pageSize,
			PageOffset: offset,
			PageCount:  pageCount,
		},
	})
}
