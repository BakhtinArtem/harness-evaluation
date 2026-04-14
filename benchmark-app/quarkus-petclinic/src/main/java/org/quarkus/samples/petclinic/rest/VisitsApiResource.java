package org.quarkus.samples.petclinic.rest;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.quarkus.samples.petclinic.owner.Owner;
import org.quarkus.samples.petclinic.owner.Pet;
import org.quarkus.samples.petclinic.visit.Visit;

import java.net.URI;
import java.util.List;

@Path("/api/owners/{ownerId}/pets/{petId}/visits")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class VisitsApiResource {

    @GET
    public List<VisitDto> listPetVisits(@PathParam("ownerId") Long ownerId, @PathParam("petId") Long petId) {
        validateOwnerPet(ownerId, petId);
        return Visit.<Visit>list("petId", petId).stream().map(ApiMapper::toVisitDto).toList();
    }

    @POST
    @Transactional
    public Response addVisitToOwnerPet(@PathParam("ownerId") Long ownerId, @PathParam("petId") Long petId, VisitDto visitDto) {
        validateOwnerPet(ownerId, petId);
        Visit visit = new Visit();
        visit.petId = petId;
        visit.date = visitDto.date;
        visit.description = visitDto.description;
        visit.persist();
        return Response.created(URI.create("/api/visits/" + visit.id)).entity(ApiMapper.toVisitDto(visit)).build();
    }

    private void validateOwnerPet(Long ownerId, Long petId) {
        Owner owner = Owner.findById(ownerId);
        Pet pet = Pet.findById(petId);
        if (owner == null || pet == null || pet.owner == null || !owner.id.equals(pet.owner.id)) {
            throw new NotFoundException();
        }
    }
}
