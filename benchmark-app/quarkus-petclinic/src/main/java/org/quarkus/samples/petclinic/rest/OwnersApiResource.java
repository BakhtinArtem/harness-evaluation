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

import java.net.URI;
import java.util.List;

@Path("/api/owners")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class OwnersApiResource {

    @GET
    public List<OwnerDto> listOwners() {
        return Owner.<Owner>listAll().stream().map(ApiMapper::toOwnerDto).toList();
    }

    @POST
    @Transactional
    public Response addOwner(OwnerDto ownerDto) {
        Owner owner = new Owner();
        owner.firstName = ownerDto.firstName;
        owner.lastName = ownerDto.lastName;
        owner.address = ownerDto.address;
        owner.city = ownerDto.city;
        owner.telephone = ownerDto.telephone;
        owner.persist();
        return Response.created(URI.create("/api/owners/" + owner.id)).entity(ApiMapper.toOwnerDto(owner)).build();
    }

    @GET
    @Path("/{ownerId}")
    public OwnerDto getOwner(@PathParam("ownerId") Long ownerId) {
        Owner owner = Owner.findById(ownerId);
        if (owner == null) {
            throw new NotFoundException();
        }
        return ApiMapper.toOwnerDto(owner);
    }

    @PUT
    @Path("/{ownerId}")
    @Transactional
    public OwnerDto updateOwner(@PathParam("ownerId") Long ownerId, OwnerDto ownerDto) {
        Owner owner = Owner.findById(ownerId);
        if (owner == null) {
            throw new NotFoundException();
        }
        owner.firstName = ownerDto.firstName;
        owner.lastName = ownerDto.lastName;
        owner.address = ownerDto.address;
        owner.city = ownerDto.city;
        owner.telephone = ownerDto.telephone;
        return ApiMapper.toOwnerDto(owner);
    }

    @DELETE
    @Path("/{ownerId}")
    @Transactional
    public Response deleteOwner(@PathParam("ownerId") Long ownerId) {
        Owner owner = Owner.findById(ownerId);
        if (owner == null) {
            throw new NotFoundException();
        }
        owner.delete();
        return Response.noContent().build();
    }
}
