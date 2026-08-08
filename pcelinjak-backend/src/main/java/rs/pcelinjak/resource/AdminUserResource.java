package rs.pcelinjak.resource;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import rs.pcelinjak.auth.AdminSecured;
import rs.pcelinjak.entity.User;
import rs.pcelinjak.service.MailService;
import rs.pcelinjak.util.TokenUtil;

import jakarta.inject.Inject;
import java.util.Map;

/**
 * Ops helpers when activation email/SMTP is down.
 * Requires X-Admin-Key when pcelinjak.admin-api-key is set.
 */
@Path("/admin/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@AdminSecured
public class AdminUserResource {

    private static final Logger LOG = Logger.getLogger(AdminUserResource.class);

    @Inject
    MailService mailService;

    public static class EmailRequest {
        public String email;
    }

    @POST
    @Path("/activate")
    @Transactional
    public Response activate(EmailRequest req) {
        if (req == null || req.email == null || req.email.isBlank()) {
            return Response.status(400).entity(Map.of("message", "email je obavezan")).build();
        }
        User user = User.findByEmail(req.email.trim().toLowerCase());
        if (user == null) {
            return Response.status(404).entity(Map.of("message", "Korisnik nije pronađen")).build();
        }
        user.activated = true;
        user.activationKey = null;
        user.persist();
        LOG.infof("Admin activated user %s", user.email);
        return Response.ok(Map.of("message", "Nalog je aktiviran", "email", user.email)).build();
    }

    @POST
    @Path("/resend-activation")
    @Transactional
    public Response resendActivation(EmailRequest req) {
        if (req == null || req.email == null || req.email.isBlank()) {
            return Response.status(400).entity(Map.of("message", "email je obavezan")).build();
        }
        User user = User.findByEmail(req.email.trim().toLowerCase());
        if (user == null) {
            return Response.status(404).entity(Map.of("message", "Korisnik nije pronađen")).build();
        }
        if (user.activated) {
            return Response.status(400).entity(Map.of("message", "Nalog je već aktiviran")).build();
        }
        if (user.activationKey == null || user.activationKey.isBlank()) {
            user.activationKey = TokenUtil.generateActivationKey();
            user.persist();
        }
        try {
            mailService.sendActivationEmail(user);
            return Response.ok(Map.of("message", "Aktivacioni email je poslat", "email", user.email)).build();
        } catch (Exception e) {
            LOG.errorf(e, "Admin resend activation failed for %s", user.email);
            return Response.status(502)
                    .entity(Map.of(
                            "message", "SMTP greška pri slanju emaila",
                            "email", user.email,
                            "activationKey", user.activationKey))
                    .build();
        }
    }
}
