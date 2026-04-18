package handlers

import (
	"net/http"
	"strings"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

// loadOwner fetches an owner by id and preloads its pets (with type+visits).
func (h *Handler) loadOwner(id int32) (*models.Owner, error) {
	var owner models.Owner
	err := h.DB.
		Preload("Pets.Type").
		Preload("Pets.Visits").
		First(&owner, id).Error
	if err != nil {
		return nil, err
	}
	if owner.Pets == nil {
		owner.Pets = []models.Pet{}
	}
	for i := range owner.Pets {
		if owner.Pets[i].Visits == nil {
			owner.Pets[i].Visits = []models.Visit{}
		}
	}
	return &owner, nil
}

// ListOwners handles GET /owners?lastName=...
func (h *Handler) ListOwners(w http.ResponseWriter, r *http.Request) {
	q := h.DB.
		Preload("Pets.Type").
		Preload("Pets.Visits").
		Order("id ASC")

	if ln := strings.TrimSpace(r.URL.Query().Get("lastName")); ln != "" {
		q = q.Where("last_name LIKE ?", ln+"%")
	}

	var owners []models.Owner
	if err := q.Find(&owners).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	for i := range owners {
		if owners[i].Pets == nil {
			owners[i].Pets = []models.Pet{}
		}
		for j := range owners[i].Pets {
			if owners[i].Pets[j].Visits == nil {
				owners[i].Pets[j].Visits = []models.Visit{}
			}
		}
	}
	httpx.WriteJSON(w, http.StatusOK, owners)
}

// AddOwner handles POST /owners
func (h *Handler) AddOwner(w http.ResponseWriter, r *http.Request) {
	var in models.Owner
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	in.ID = 0
	in.Pets = nil
	if err := h.DB.Create(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	owner, err := h.loadOwner(in.ID)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, owner)
}

// GetOwner handles GET /owners/{ownerId}
func (h *Handler) GetOwner(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	owner, err := h.loadOwner(id)
	if err != nil {
		if notFoundIfMissing(w, err, "owner not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, owner)
}

// UpdateOwner handles PUT /owners/{ownerId}
func (h *Handler) UpdateOwner(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	var in models.Owner
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	existing, err := h.loadOwner(id)
	if err != nil {
		if notFoundIfMissing(w, err, "owner not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	existing.FirstName = in.FirstName
	existing.LastName = in.LastName
	existing.Address = in.Address
	existing.City = in.City
	existing.Telephone = in.Telephone
	if err := h.DB.Model(existing).Updates(map[string]any{
		"first_name": existing.FirstName,
		"last_name":  existing.LastName,
		"address":    existing.Address,
		"city":       existing.City,
		"telephone":  existing.Telephone,
	}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	reloaded, err := h.loadOwner(id)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, reloaded)
}

// DeleteOwner handles DELETE /owners/{ownerId}
func (h *Handler) DeleteOwner(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	res := h.DB.Delete(&models.Owner{}, id)
	if res.Error != nil {
		httpx.BadRequest(w, res.Error.Error())
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w, "owner not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
