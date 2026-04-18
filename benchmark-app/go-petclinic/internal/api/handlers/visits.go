package handlers

import (
	"net/http"
	"time"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

// ListVisits handles GET /visits.
func (h *Handler) ListVisits(w http.ResponseWriter, r *http.Request) {
	var visits []models.Visit
	if err := h.DB.Order("id ASC").Find(&visits).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, visits)
}

// AddVisit handles POST /visits.
func (h *Handler) AddVisit(w http.ResponseWriter, r *http.Request) {
	var in models.Visit
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	in.ID = 0
	if in.Date.Time.IsZero() {
		in.Date = models.LocalDate{Time: time.Now().UTC()}
	}

	var pet models.Pet
	if err := h.DB.First(&pet, in.PetID).Error; err != nil {
		if notFoundIfMissing(w, err, "pet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	if err := h.DB.Create(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, in)
}

// GetVisit handles GET /visits/{visitId}.
func (h *Handler) GetVisit(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "visitId")
	if !ok {
		return
	}
	var visit models.Visit
	if err := h.DB.First(&visit, id).Error; err != nil {
		if notFoundIfMissing(w, err, "visit not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, visit)
}

// UpdateVisit handles PUT /visits/{visitId}.
func (h *Handler) UpdateVisit(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "visitId")
	if !ok {
		return
	}
	var existing models.Visit
	if err := h.DB.First(&existing, id).Error; err != nil {
		if notFoundIfMissing(w, err, "visit not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	var in models.Visit
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	existing.Description = in.Description
	if !in.Date.Time.IsZero() {
		existing.Date = in.Date
	}
	if err := h.DB.Model(&existing).Updates(map[string]any{
		"description": existing.Description,
		"visit_date":  existing.Date,
	}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, existing)
}

// DeleteVisit handles DELETE /visits/{visitId}.
func (h *Handler) DeleteVisit(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "visitId")
	if !ok {
		return
	}
	res := h.DB.Delete(&models.Visit{}, id)
	if res.Error != nil {
		httpx.BadRequest(w, res.Error.Error())
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w, "visit not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// AddVisitToOwner handles POST /owners/{ownerId}/pets/{petId}/visits.
func (h *Handler) AddVisitToOwner(w http.ResponseWriter, r *http.Request) {
	ownerID, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	petID, ok := pathInt32(w, r, "petId")
	if !ok {
		return
	}
	var pet models.Pet
	if err := h.DB.First(&pet, petID).Error; err != nil {
		if notFoundIfMissing(w, err, "pet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	if pet.OwnerID == nil || *pet.OwnerID != ownerID {
		httpx.NotFound(w, "pet does not belong to owner")
		return
	}
	var in models.Visit
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	in.ID = 0
	in.PetID = petID
	if in.Date.Time.IsZero() {
		in.Date = models.LocalDate{Time: time.Now().UTC()}
	}
	if err := h.DB.Create(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, in)
}
