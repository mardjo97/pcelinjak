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
        MeResponse res = new MeResponse();
        res.userId = user.id;
        res.email = user.email;
        res.name = user.name;
        res.needsFcmRefresh = user.needsFcmRefresh;
        return Response.ok(res).build();
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

        MeResponse res = new MeResponse();
        res.userId = user.id;
        res.email = user.email;
        res.name = user.name;
        res.needsFcmRefresh = false;
        return Response.ok(res).build();
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
