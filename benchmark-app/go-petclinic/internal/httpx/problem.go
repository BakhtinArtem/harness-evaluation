package httpx

import (
	"encoding/json"
	"net/http"
	"time"
)

// Problem is an RFC 7807 compatible error body (matches Spring's ProblemDetail).
type Problem struct {
	Type      string    `json:"type"`
	Title     string    `json:"title"`
	Status    int       `json:"status"`
	Detail    string    `json:"detail"`
	Timestamp time.Time `json:"timestamp"`
}

// WriteProblem renders a ProblemDetail JSON response.
func WriteProblem(w http.ResponseWriter, status int, title, detail string) {
	p := Problem{
		Type:      "about:blank",
		Title:     title,
		Status:    status,
		Detail:    detail,
		Timestamp: time.Now().UTC(),
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(p)
}

// BadRequest writes a 400 problem.
func BadRequest(w http.ResponseWriter, detail string) {
	WriteProblem(w, http.StatusBadRequest, "Bad Request", detail)
}

// NotFound writes a 404 problem.
func NotFound(w http.ResponseWriter, detail string) {
	WriteProblem(w, http.StatusNotFound, "Not Found", detail)
}

// ServerError writes a 500 problem.
func ServerError(w http.ResponseWriter, detail string) {
	WriteProblem(w, http.StatusInternalServerError, "Internal Server Error", detail)
}
