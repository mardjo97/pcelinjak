package rs.pcelinjak.resource;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import rs.pcelinjak.dto.AuthDto;
import rs.pcelinjak.entity.Feedback;
import rs.pcelinjak.entity.User;

import java.util.Map;

@Path("/api/feedback")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class FeedbackResource {

    public static class FeedbackRequest {
        public String message;
        public String email;
        public String appVersion;
        public String locale;
    }

    @POST
    @Transactional
    public Response submit(FeedbackRequest req, @Context ContainerRequestContext ctx) {
        if (req == null || req.message == null || req.message.isBlank()) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Poruka je obavezna.")).build();
        }
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);

        Feedback f = new Feedback();
        f.userId = userId;
        f.email = req.email != null && !req.email.isBlank()
                ? req.email.trim()
                : (user != null ? user.email : null);
        f.message = req.message.trim();
        if (f.message.length() > 4000) {
            f.message = f.message.substring(0, 4000);
        }
        f.appVersion = req.appVersion;
        f.locale = req.locale;
        f.persist();

        return Response.status(Response.Status.CREATED)
                .entity(Map.of("id", f.id, "message", "Hvala na povratnoj informaciji."))
                .build();
    }
}
