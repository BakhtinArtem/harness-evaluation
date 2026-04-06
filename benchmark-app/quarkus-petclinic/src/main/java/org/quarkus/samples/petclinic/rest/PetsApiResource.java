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
import org.quarkus.samples.petclinic.owner.PetType;

import java.net.URI;
import java.util.List;

@Path("/api/owners/{ownerId}/pets")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PetsApiResource {

    @GET
    public List<PetDto> listOwnerPets(@PathParam("ownerId") Long ownerId) {
        Owner owner = Owner.findById(ownerId);
        if (owner == null) {
            throw new NotFoundException();
        }
        return Pet.<Pet>list("owner.id", ownerId).stream().map(ApiMapper::toPetDto).toList();
    }

    @POST
    @Transactional
    public Response addPetToOwner(@PathParam("ownerId") Long ownerId, PetDto petDto) {
        Owner owner = Owner.findById(ownerId);
        if (owner == null) {
            throw new NotFoundException();
        }
        PetType petType = PetType.findById(petDto.typeId);
        if (petType == null) {
            throw new NotFoundException();
        }
        Pet pet = new Pet();
        pet.name = petDto.name;
        pet.birthDate = petDto.birthDate;
        pet.type = petType;
        pet.owner = owner;
        pet.persist();
        return Response.created(URI.create("/api/pets/" + pet.id)).entity(ApiMapper.toPetDto(pet)).build();
    }

}
