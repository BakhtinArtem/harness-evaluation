package handlers

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/go-chi/chi/v5"
	"gorm.io/gorm"
)

// Handler groups resource handlers bound to a single database connection.
type Handler struct {
	DB *gorm.DB
}

// New constructs a Handler bound to the provided GORM DB.
func New(db *gorm.DB) *Handler { return &Handler{DB: db} }

// pathInt32 extracts a path parameter as int32 or writes a 400 problem.
func pathInt32(w http.ResponseWriter, r *http.Request, name string) (int32, bool) {
	raw := chi.URLParam(r, name)
	v, err := strconv.ParseInt(raw, 10, 32)
	if err != nil {
		httpx.BadRequest(w, "invalid "+name+": "+raw)
		return 0, false
	}
	return int32(v), true
}

// notFoundIfMissing returns true if err is a gorm record-not-found error and
// also writes a 404 response. Returns false for other errors.
func notFoundIfMissing(w http.ResponseWriter, err error, detail string) bool {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		httpx.NotFound(w, detail)
		return true
	}
	return false
}
