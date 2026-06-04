package api

import "net/http"

func healthCheck(w http.ResponseWriter, r *http.Request) {
	ok(w, r, envelope{Data: "Success"})
}
