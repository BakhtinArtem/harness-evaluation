package org.quarkus.samples.petclinic.rest;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.quarkus.samples.petclinic.owner.Pet;
import org.quarkus.samples.petclinic.owner.PetType;

@Path("/api/pets/{petId}")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PetItemApiResource {

    @GET
    public PetDto getPet(@PathParam("petId") Long petId) {
        Pet pet = Pet.findById(petId);
        if (pet == null) {
            throw new NotFoundException();
        }
        return ApiMapper.toPetDto(pet);
    }

    @PUT
    @Transactional
    public PetDto updatePet(@PathParam("petId") Long petId, PetDto petDto) {
        Pet pet = Pet.findById(petId);
        if (pet == null) {
            throw new NotFoundException();
        }
        PetType petType = PetType.findById(petDto.typeId);
        if (petType == null) {
            throw new NotFoundException();
        }
        pet.name = petDto.name;
        pet.birthDate = petDto.birthDate;
        pet.type = petType;
        return ApiMapper.toPetDto(pet);
    }

    @DELETE
    @Transactional
    public Response deletePet(@PathParam("petId") Long petId) {
        Pet pet = Pet.findById(petId);
        if (pet == null) {
            throw new NotFoundException();
        }
        pet.delete();
        return Response.noContent().build();
    }
}
