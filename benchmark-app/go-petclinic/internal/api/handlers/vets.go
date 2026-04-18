package handlers

import (
	"net/http"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

func (h *Handler) loadVet(id int32) (*models.Vet, error) {
	var vet models.Vet
	err := h.DB.Preload("Specialties").First(&vet, id).Error
	if err != nil {
		return nil, err
	}
	if vet.Specialties == nil {
		vet.Specialties = []models.Specialty{}
	}
	return &vet, nil
}

// ListVets handles GET /vets.
func (h *Handler) ListVets(w http.ResponseWriter, r *http.Request) {
	var vets []models.Vet
	if err := h.DB.Preload("Specialties").Order("id ASC").Find(&vets).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	for i := range vets {
		if vets[i].Specialties == nil {
			vets[i].Specialties = []models.Specialty{}
		}
	}
	httpx.WriteJSON(w, http.StatusOK, vets)
}

// AddVet handles POST /vets.
func (h *Handler) AddVet(w http.ResponseWriter, r *http.Request) {
	var in models.Vet
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	in.ID = 0

	resolvedSpecs, err := h.resolveSpecialties(in.Specialties)
	if err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	in.Specialties = nil

	if err := h.DB.Create(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if len(resolvedSpecs) > 0 {
		if err := h.DB.Model(&in).Association("Specialties").Replace(resolvedSpecs); err != nil {
			httpx.BadRequest(w, err.Error())
			return
		}
	}
	vet, err := h.loadVet(in.ID)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, vet)
}

// GetVet handles GET /vets/{vetId}.
func (h *Handler) GetVet(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "vetId")
	if !ok {
		return
	}
	vet, err := h.loadVet(id)
	if err != nil {
		if notFoundIfMissing(w, err, "vet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, vet)
}

// UpdateVet handles PUT /vets/{vetId}.
func (h *Handler) UpdateVet(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "vetId")
	if !ok {
		return
	}
	existing, err := h.loadVet(id)
	if err != nil {
		if notFoundIfMissing(w, err, "vet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	var in models.Vet
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	existing.FirstName = in.FirstName
	existing.LastName = in.LastName

	resolvedSpecs, err := h.resolveSpecialties(in.Specialties)
	if err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}

	if err := h.DB.Model(existing).Updates(map[string]any{
		"first_name": existing.FirstName,
		"last_name":  existing.LastName,
	}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	if err := h.DB.Model(existing).Association("Specialties").Replace(resolvedSpecs); err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	reloaded, err := h.loadVet(id)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, reloaded)
}

// DeleteVet handles DELETE /vets/{vetId}.
func (h *Handler) DeleteVet(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "vetId")
	if !ok {
		return
	}
	if err := h.DB.Exec("DELETE FROM vet_specialties WHERE vet_id = ?", id).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	res := h.DB.Delete(&models.Vet{}, id)
	if res.Error != nil {
		httpx.BadRequest(w, res.Error.Error())
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w, "vet not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// resolveSpecialties replaces any specialty payload with the persisted row,
// creating missing ones only when an id is not provided.
func (h *Handler) resolveSpecialties(in []models.Specialty) ([]models.Specialty, error) {
	out := make([]models.Specialty, 0, len(in))
	for _, s := range in {
		var resolved models.Specialty
		switch {
		case s.ID != 0:
			if err := h.DB.First(&resolved, s.ID).Error; err != nil {
				return nil, err
			}
		case s.Name != "":
			if err := h.DB.Where("name = ?", s.Name).First(&resolved).Error; err != nil {
				resolved = models.Specialty{Name: s.Name}
				if err := h.DB.Create(&resolved).Error; err != nil {
					return nil, err
				}
			}
		default:
			continue
		}
		out = append(out, resolved)
	}
	return out, nil
}
