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
import org.quarkus.samples.petclinic.visit.Visit;

@Path("/api/visits/{visitId}")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class VisitItemApiResource {

    @GET
    public VisitDto getVisit(@PathParam("visitId") Long visitId) {
        Visit visit = Visit.findById(visitId);
        if (visit == null) {
            throw new NotFoundException();
        }
        return ApiMapper.toVisitDto(visit);
    }

    @PUT
    @Transactional
    public VisitDto updateVisit(@PathParam("visitId") Long visitId, VisitDto visitDto) {
        Visit visit = Visit.findById(visitId);
        if (visit == null) {
            throw new NotFoundException();
        }
        visit.date = visitDto.date;
        visit.description = visitDto.description;
        return ApiMapper.toVisitDto(visit);
    }

    @DELETE
    @Transactional
    public Response deleteVisit(@PathParam("visitId") Long visitId) {
        Visit visit = Visit.findById(visitId);
        if (visit == null) {
            throw new NotFoundException();
        }
        visit.delete();
        return Response.noContent().build();
    }
}
