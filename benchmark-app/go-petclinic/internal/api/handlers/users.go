package handlers

import (
	"net/http"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

// AddUser handles POST /users. Role FKs require the user row to exist first,
// so roles are inserted after the user is persisted.
func (h *Handler) AddUser(w http.ResponseWriter, r *http.Request) {
	var in models.User
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	if in.Username == "" {
		httpx.BadRequest(w, "username is required")
		return
	}
	roles := in.Roles
	in.Roles = nil
	if err := h.DB.Save(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	for _, role := range roles {
		role.ID = 0
		role.Username = in.Username
		if err := h.DB.Create(&role).Error; err != nil {
			httpx.BadRequest(w, err.Error())
			return
		}
	}
	var persisted models.User
	if err := h.DB.Preload("Roles").First(&persisted, "username = ?", in.Username).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, persisted)
}
