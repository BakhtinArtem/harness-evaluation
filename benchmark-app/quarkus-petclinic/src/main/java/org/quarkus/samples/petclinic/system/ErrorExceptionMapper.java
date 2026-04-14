package org.quarkus.samples.petclinic.system;

import jakarta.inject.Inject;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.NotSupportedException;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.jboss.resteasy.reactive.server.ServerExceptionMapper;

public class ErrorExceptionMapper {

    private static final Logger LOG = Logger.getLogger(ErrorExceptionMapper.class);
    public static final String ERROR_HEADER = "x-error";

    @Inject
    TemplatesLocale templates;

    @ServerExceptionMapper
    public Response map(Exception exception, ContainerRequestContext requestContext) {
        LOG.error("Internal application error", exception);
        String requestPath = requestContext.getUriInfo().getPath();
        if (requestPath.startsWith("api/")) {
            int status = Response.Status.INTERNAL_SERVER_ERROR.getStatusCode();
            if (exception instanceof NotFoundException) {
                status = Response.Status.NOT_FOUND.getStatusCode();
            } else if (exception instanceof NotSupportedException) {
                status = Response.Status.UNSUPPORTED_MEDIA_TYPE.getStatusCode();
            }
            return Response.status(status)
                .type(MediaType.APPLICATION_JSON_TYPE)
                .entity(java.util.Map.of("error", exception.getMessage()))
                .build();
        }
        return Response.ok(templates.error(exception.getMessage())).header(ERROR_HEADER, true).build();
    }

}
