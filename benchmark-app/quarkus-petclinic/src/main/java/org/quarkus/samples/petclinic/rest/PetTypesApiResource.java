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
import org.quarkus.samples.petclinic.owner.PetType;

import java.net.URI;
import java.util.List;

@Path("/api/pettypes")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PetTypesApiResource {

    @GET
    public List<PetTypeDto> listPetTypes() {
        return PetType.<PetType>listAll().stream().map(ApiMapper::toPetTypeDto).toList();
    }

    @POST
    @Transactional
    public Response addPetType(PetTypeDto petTypeDto) {
        PetType petType = new PetType();
        petType.name = petTypeDto.name;
        petType.persist();
        return Response.created(URI.create("/api/pettypes/" + petType.id)).entity(ApiMapper.toPetTypeDto(petType)).build();
    }

    @GET
    @Path("/{petTypeId}")
    public PetTypeDto getPetType(@PathParam("petTypeId") Long petTypeId) {
        PetType petType = PetType.findById(petTypeId);
        if (petType == null) {
            throw new NotFoundException();
        }
        return ApiMapper.toPetTypeDto(petType);
    }

    @PUT
    @Path("/{petTypeId}")
    @Transactional
    public PetTypeDto updatePetType(@PathParam("petTypeId") Long petTypeId, PetTypeDto petTypeDto) {
        PetType petType = PetType.findById(petTypeId);
        if (petType == null) {
            throw new NotFoundException();
        }
        petType.name = petTypeDto.name;
        return ApiMapper.toPetTypeDto(petType);
    }

    @DELETE
    @Path("/{petTypeId}")
    @Transactional
    public Response deletePetType(@PathParam("petTypeId") Long petTypeId) {
        PetType petType = PetType.findById(petTypeId);
        if (petType == null) {
            throw new NotFoundException();
        }
        petType.delete();
        return Response.noContent().build();
    }
}
