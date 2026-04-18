package api

import (
	"net/http"

	"github.com/aape2k/go-petclinic/internal/api/handlers"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"gorm.io/gorm"
)

// NewRouter wires every OpenAPI path+operationId to its handler, mounted under
// apiBase (e.g. "/petclinic/api").
func NewRouter(db *gorm.DB, apiBase string) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Recoverer)

	h := handlers.New(db)

	apiRouter := chi.NewRouter()

	apiRouter.Route("/owners", func(r chi.Router) {
		r.Get("/", h.ListOwners)
		r.Post("/", h.AddOwner)
		r.Route("/{ownerId}", func(r chi.Router) {
			r.Get("/", h.GetOwner)
			r.Put("/", h.UpdateOwner)
			r.Delete("/", h.DeleteOwner)
			r.Post("/pets", h.AddPetToOwner)
			r.Get("/pets/{petId}", h.GetOwnersPet)
			r.Put("/pets/{petId}", h.UpdateOwnersPet)
			r.Post("/pets/{petId}/visits", h.AddVisitToOwner)
		})
	})

	apiRouter.Route("/pets", func(r chi.Router) {
		r.Get("/", h.ListPets)
		r.Get("/{petId}", h.GetPet)
		r.Put("/{petId}", h.UpdatePet)
		r.Delete("/{petId}", h.DeletePet)
	})

	apiRouter.Route("/visits", func(r chi.Router) {
		r.Get("/", h.ListVisits)
		r.Post("/", h.AddVisit)
		r.Get("/{visitId}", h.GetVisit)
		r.Put("/{visitId}", h.UpdateVisit)
		r.Delete("/{visitId}", h.DeleteVisit)
	})

	apiRouter.Route("/vets", func(r chi.Router) {
		r.Get("/", h.ListVets)
		r.Post("/", h.AddVet)
		r.Get("/{vetId}", h.GetVet)
		r.Put("/{vetId}", h.UpdateVet)
		r.Delete("/{vetId}", h.DeleteVet)
	})

	apiRouter.Route("/specialties", func(r chi.Router) {
		r.Get("/", h.ListSpecialties)
		r.Post("/", h.AddSpecialty)
		r.Get("/{specialtyId}", h.GetSpecialty)
		r.Put("/{specialtyId}", h.UpdateSpecialty)
		r.Delete("/{specialtyId}", h.DeleteSpecialty)
	})

	apiRouter.Route("/pettypes", func(r chi.Router) {
		r.Get("/", h.ListPetTypes)
		r.Post("/", h.AddPetType)
		r.Get("/{petTypeId}", h.GetPetType)
		r.Put("/{petTypeId}", h.UpdatePetType)
		r.Delete("/{petTypeId}", h.DeletePetType)
	})

	apiRouter.Post("/users", h.AddUser)
	apiRouter.Get("/oops", h.FailingRequest)

	if apiBase == "" {
		r.Mount("/", apiRouter)
	} else {
		r.Mount(apiBase, apiRouter)
	}

	return r
}
