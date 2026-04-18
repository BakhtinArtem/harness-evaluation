package handlers

import (
	"net/http"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

// ListPetTypes handles GET /pettypes.
func (h *Handler) ListPetTypes(w http.ResponseWriter, r *http.Request) {
	var items []models.PetType
	if err := h.DB.Order("id ASC").Find(&items).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, items)
}

// AddPetType handles POST /pettypes.
func (h *Handler) AddPetType(w http.ResponseWriter, r *http.Request) {
	var in models.PetType
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

// GetPetType handles GET /pettypes/{petTypeId}.
func (h *Handler) GetPetType(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "petTypeId")
	if !ok {
		return
	}
	var item models.PetType
	if err := h.DB.First(&item, id).Error; err != nil {
		if notFoundIfMissing(w, err, "pet type not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, item)
}

// UpdatePetType handles PUT /pettypes/{petTypeId}.
func (h *Handler) UpdatePetType(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "petTypeId")
	if !ok {
		return
	}
	var existing models.PetType
	if err := h.DB.First(&existing, id).Error; err != nil {
		if notFoundIfMissing(w, err, "pet type not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	var in models.PetType
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

// DeletePetType handles DELETE /pettypes/{petTypeId}.
func (h *Handler) DeletePetType(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "petTypeId")
	if !ok {
		return
	}
	var inUse int64
	if err := h.DB.Model(&models.Pet{}).Where("type_id = ?", id).Count(&inUse).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	if inUse > 0 {
		httpx.BadRequest(w, "pet type is in use")
		return
	}
	res := h.DB.Delete(&models.PetType{}, id)
	if res.Error != nil {
		httpx.BadRequest(w, res.Error.Error())
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w, "pet type not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
