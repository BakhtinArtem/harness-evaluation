package handlers

import (
	"net/http"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

// ListSpecialties handles GET /specialties.
func (h *Handler) ListSpecialties(w http.ResponseWriter, r *http.Request) {
	var items []models.Specialty
	if err := h.DB.Order("id ASC").Find(&items).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, items)
}

// AddSpecialty handles POST /specialties.
func (h *Handler) AddSpecialty(w http.ResponseWriter, r *http.Request) {
	var in models.Specialty
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	in.ID = 0
	if err := h.DB.Create(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, in)
}

// GetSpecialty handles GET /specialties/{specialtyId}.
func (h *Handler) GetSpecialty(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "specialtyId")
	if !ok {
		return
	}
	var item models.Specialty
	if err := h.DB.First(&item, id).Error; err != nil {
		if notFoundIfMissing(w, err, "specialty not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, item)
}

// UpdateSpecialty handles PUT /specialties/{specialtyId}.
func (h *Handler) UpdateSpecialty(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "specialtyId")
	if !ok {
		return
	}
	var existing models.Specialty
	if err := h.DB.First(&existing, id).Error; err != nil {
		if notFoundIfMissing(w, err, "specialty not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	var in models.Specialty
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	existing.Name = in.Name
	if err := h.DB.Model(&existing).Updates(map[string]any{"name": existing.Name}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, existing)
}

// DeleteSpecialty handles DELETE /specialties/{specialtyId}.
func (h *Handler) DeleteSpecialty(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "specialtyId")
	if !ok {
		return
	}
	if err := h.DB.Exec("DELETE FROM vet_specialties WHERE specialty_id = ?", id).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	res := h.DB.Delete(&models.Specialty{}, id)
	if res.Error != nil {
		httpx.BadRequest(w, res.Error.Error())
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w, "specialty not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
