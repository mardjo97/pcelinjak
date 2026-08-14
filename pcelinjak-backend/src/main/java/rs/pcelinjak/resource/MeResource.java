package rs.pcelinjak.resource;

import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import rs.pcelinjak.dto.AuthDto;
import rs.pcelinjak.entity.User;
import rs.pcelinjak.notification.NotificationClient;
import rs.pcelinjak.util.PersonName;

@Path("/me")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MeResource {

    @Inject
    NotificationClient notificationClient;

    public static class MeResponse {
        public Long userId;
        public String email;
        public String name;
        public String firstName;
        public String lastName;
        public String phone;
        public boolean needsFcmRefresh;
    }

    public static class DeviceRequest {
        public String deviceId;
        public String fcmToken;
    }

    @GET
    public Response me(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);
        if (user == null) {
            return Response.status(404).entity(new AuthDto.MessageResponse("Korisnik nije pronađen.")).build();
        }
        return Response.ok(toMe(user)).build();
    }

    @PUT
    @Transactional
    public Response update(AuthDto.UpdateProfileRequest req, @Context ContainerRequestContext ctx) {
        if (req == null || isBlank(req.firstName) || isBlank(req.lastName)) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Ime i prezime su obavezni.")).build();
        }
        if (!isBlank(req.phone) && !AuthResource.isValidPhone(req.phone)) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Neispravan broj telefona.")).build();
        }
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);
        if (user == null) {
            return Response.status(404).entity(new AuthDto.MessageResponse("Korisnik nije pronađen.")).build();
        }
        PersonName.apply(user, req.firstName, req.lastName, null);
        user.phone = isBlank(req.phone) ? null : req.phone.trim();
        user.persist();
        return Response.ok(toMe(user)).build();
    }

    @PUT
    @Path("/device")
    @Transactional
    public Response upsertDevice(DeviceRequest req, @Context ContainerRequestContext ctx) {
        if (req == null || isBlank(req.deviceId) || isBlank(req.fcmToken)) {
            return Response.status(400).entity(new AuthDto.MessageResponse("deviceId i fcmToken su obavezni.")).build();
        }
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);
        if (user == null) {
            return Response.status(404).entity(new AuthDto.MessageResponse("Korisnik nije pronađen.")).build();
        }

        boolean ok = notificationClient.upsertDevice(String.valueOf(userId), req.deviceId.trim(), req.fcmToken.trim());
        if (!ok && notificationClient.isConfigured()) {
            return Response.status(502).entity(new AuthDto.MessageResponse("Registracija uređaja nije uspela.")).build();
        }

        user.needsFcmRefresh = false;
        user.persist();

        return Response.ok(toMe(user)).build();
    }

    private static MeResponse toMe(User user) {
        MeResponse res = new MeResponse();
        res.userId = user.id;
        res.email = user.email;
        res.name = user.name;
        res.firstName = user.firstName;
        res.lastName = user.lastName;
        res.phone = user.phone;
        res.needsFcmRefresh = user.needsFcmRefresh;
        return res;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
