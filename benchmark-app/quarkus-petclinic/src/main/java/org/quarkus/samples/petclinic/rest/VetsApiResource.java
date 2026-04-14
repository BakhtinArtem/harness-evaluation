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
import org.quarkus.samples.petclinic.vet.Vet;

import java.net.URI;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Path("/api/vets")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class VetsApiResource {

    @GET
    public List<VetDto> listVets() {
        return Vet.<Vet>listAll().stream().map(ApiMapper::toVetDto).toList();
    }

    @POST
    @Transactional
    public Response addVet(VetDto vetDto) {
        Vet vet = new Vet();
        vet.firstName = vetDto.firstName;
        vet.lastName = vetDto.lastName;
        vet.specialties = resolveSpecialties(vetDto.specialtyIds);
        vet.persist();
        return Response.created(URI.create("/api/vets/" + vet.id)).entity(ApiMapper.toVetDto(vet)).build();
    }

    @GET
    @Path("/{vetId}")
    public VetDto getVet(@PathParam("vetId") Long vetId) {
        Vet vet = Vet.findById(vetId);
        if (vet == null) {
            throw new NotFoundException();
        }
        return ApiMapper.toVetDto(vet);
    }

    @PUT
    @Path("/{vetId}")
    @Transactional
    public VetDto updateVet(@PathParam("vetId") Long vetId, VetDto vetDto) {
        Vet vet = Vet.findById(vetId);
        if (vet == null) {
            throw new NotFoundException();
        }
        vet.firstName = vetDto.firstName;
        vet.lastName = vetDto.lastName;
        vet.specialties = resolveSpecialties(vetDto.specialtyIds);
        return ApiMapper.toVetDto(vet);
    }

    @DELETE
    @Path("/{vetId}")
    @Transactional
    public Response deleteVet(@PathParam("vetId") Long vetId) {
        Vet vet = Vet.findById(vetId);
        if (vet == null) {
            throw new NotFoundException();
        }
        vet.delete();
        return Response.noContent().build();
    }

    private Set<Specialty> resolveSpecialties(List<Long> specialtyIds) {
        Set<Specialty> specialties = new HashSet<>();
        if (specialtyIds == null) {
            return specialties;
        }
        for (Long specialtyId : specialtyIds) {
            Specialty specialty = Specialty.findById(specialtyId);
            if (specialty == null) {
                throw new NotFoundException();
            }
            specialties.add(specialty);
        }
        return specialties;
    }
}
