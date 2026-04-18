package handlers

import (
	"net/http"

	"github.com/aape2k/go-petclinic/internal/httpx"
	"github.com/aape2k/go-petclinic/internal/models"
)

// loadPet fetches a pet by id with its type and visits preloaded.
func (h *Handler) loadPet(id int32) (*models.Pet, error) {
	var pet models.Pet
	err := h.DB.
		Preload("Type").
		Preload("Visits").
		First(&pet, id).Error
	if err != nil {
		return nil, err
	}
	if pet.Visits == nil {
		pet.Visits = []models.Visit{}
	}
	return &pet, nil
}

// ListPets handles GET /pets.
func (h *Handler) ListPets(w http.ResponseWriter, r *http.Request) {
	var pets []models.Pet
	if err := h.DB.
		Preload("Type").
		Preload("Visits").
		Order("id ASC").
		Find(&pets).Error; err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	for i := range pets {
		if pets[i].Visits == nil {
			pets[i].Visits = []models.Visit{}
		}
	}
	httpx.WriteJSON(w, http.StatusOK, pets)
}

// GetPet handles GET /pets/{petId}.
func (h *Handler) GetPet(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "petId")
	if !ok {
		return
	}
	pet, err := h.loadPet(id)
	if err != nil {
		if notFoundIfMissing(w, err, "pet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, pet)
}

// UpdatePet handles PUT /pets/{petId}.
func (h *Handler) UpdatePet(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "petId")
	if !ok {
		return
	}
	var in models.Pet
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	existing, err := h.loadPet(id)
	if err != nil {
		if notFoundIfMissing(w, err, "pet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	existing.Name = in.Name
	existing.BirthDate = in.BirthDate
	if in.Type.ID != 0 {
		existing.TypeID = in.Type.ID
	}
	if err := h.DB.Model(existing).Updates(map[string]any{
		"name":       existing.Name,
		"birth_date": existing.BirthDate,
		"type_id":    existing.TypeID,
	}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	reloaded, err := h.loadPet(id)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, reloaded)
}

// DeletePet handles DELETE /pets/{petId}.
func (h *Handler) DeletePet(w http.ResponseWriter, r *http.Request) {
	id, ok := pathInt32(w, r, "petId")
	if !ok {
		return
	}
	if err := h.DB.Where("pet_id = ?", id).Delete(&models.Visit{}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	res := h.DB.Delete(&models.Pet{}, id)
	if res.Error != nil {
		httpx.BadRequest(w, res.Error.Error())
		return
	}
	if res.RowsAffected == 0 {
		httpx.NotFound(w, "pet not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// AddPetToOwner handles POST /owners/{ownerId}/pets.
func (h *Handler) AddPetToOwner(w http.ResponseWriter, r *http.Request) {
	ownerID, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	var owner models.Owner
	if err := h.DB.First(&owner, ownerID).Error; err != nil {
		if notFoundIfMissing(w, err, "owner not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	var in models.Pet
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	in.ID = 0
	in.OwnerID = &ownerID
	if in.Type.ID != 0 {
		in.TypeID = in.Type.ID
	}
	in.Type = models.PetType{}
	in.Visits = nil
	if err := h.DB.Create(&in).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	pet, err := h.loadPet(in.ID)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	pet.OwnerID = &ownerID
	httpx.WriteJSON(w, http.StatusCreated, pet)
}

// GetOwnersPet handles GET /owners/{ownerId}/pets/{petId}.
func (h *Handler) GetOwnersPet(w http.ResponseWriter, r *http.Request) {
	ownerID, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	petID, ok := pathInt32(w, r, "petId")
	if !ok {
		return
	}
	pet, err := h.loadPet(petID)
	if err != nil {
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
	httpx.WriteJSON(w, http.StatusOK, pet)
}

// UpdateOwnersPet handles PUT /owners/{ownerId}/pets/{petId}.
func (h *Handler) UpdateOwnersPet(w http.ResponseWriter, r *http.Request) {
	ownerID, ok := pathInt32(w, r, "ownerId")
	if !ok {
		return
	}
	petID, ok := pathInt32(w, r, "petId")
	if !ok {
		return
	}
	existing, err := h.loadPet(petID)
	if err != nil {
		if notFoundIfMissing(w, err, "pet not found") {
			return
		}
		httpx.ServerError(w, err.Error())
		return
	}
	if existing.OwnerID == nil || *existing.OwnerID != ownerID {
		httpx.NotFound(w, "pet does not belong to owner")
		return
	}
	var in models.Pet
	if !httpx.DecodeJSON(w, r, &in) {
		return
	}
	existing.Name = in.Name
	existing.BirthDate = in.BirthDate
	if in.Type.ID != 0 {
		existing.TypeID = in.Type.ID
	}
	if err := h.DB.Model(existing).Updates(map[string]any{
		"name":       existing.Name,
		"birth_date": existing.BirthDate,
		"type_id":    existing.TypeID,
	}).Error; err != nil {
		httpx.BadRequest(w, err.Error())
		return
	}
	reloaded, err := h.loadPet(petID)
	if err != nil {
		httpx.ServerError(w, err.Error())
		return
	}
	httpx.WriteJSON(w, http.StatusOK, reloaded)
}
