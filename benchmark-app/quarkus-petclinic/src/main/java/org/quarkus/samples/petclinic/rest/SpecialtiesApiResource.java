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
import org.quarkus.samples.petclinic.vet.Specialty;

import java.net.URI;
import java.util.List;

@Path("/api/specialties")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class SpecialtiesApiResource {

    @GET
    public List<SpecialtyDto> listSpecialties() {
        return Specialty.<Specialty>listAll().stream().map(ApiMapper::toSpecialtyDto).toList();
    }

    @POST
    @Transactional
    public Response addSpecialty(SpecialtyDto specialtyDto) {
        Specialty specialty = new Specialty();
        specialty.name = specialtyDto.name;
        specialty.persist();
        return Response.created(URI.create("/api/specialties/" + specialty.id)).entity(ApiMapper.toSpecialtyDto(specialty)).build();
    }

    @GET
    @Path("/{specialtyId}")
    public SpecialtyDto getSpecialty(@PathParam("specialtyId") Long specialtyId) {
        Specialty specialty = Specialty.findById(specialtyId);
        if (specialty == null) {
            throw new NotFoundException();
        }
        return ApiMapper.toSpecialtyDto(specialty);
    }

    @PUT
    @Path("/{specialtyId}")
    @Transactional
    public SpecialtyDto updateSpecialty(@PathParam("specialtyId") Long specialtyId, SpecialtyDto specialtyDto) {
        Specialty specialty = Specialty.findById(specialtyId);
        if (specialty == null) {
            throw new NotFoundException();
        }
        specialty.name = specialtyDto.name;
        return ApiMapper.toSpecialtyDto(specialty);
    }

    @DELETE
    @Path("/{specialtyId}")
    @Transactional
    public Response deleteSpecialty(@PathParam("specialtyId") Long specialtyId) {
        Specialty specialty = Specialty.findById(specialtyId);
        if (specialty == null) {
            throw new NotFoundException();
        }
        specialty.delete();
        return Response.noContent().build();
    }
}
