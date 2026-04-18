package handlers

import "net/http"

// FailingRequest handles GET /oops and returns plain text 200 per the OpenAPI
// spec (the endpoint exists only as a stable terminal node for benchmark chains).
func (h *Handler) FailingRequest(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("failure-sample path hit"))
}
