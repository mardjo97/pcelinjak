package rs.pcelinjak.resource;

import at.favre.lib.crypto.bcrypt.BCrypt;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import rs.pcelinjak.auth.JwtService;
import rs.pcelinjak.dto.AuthDto;
import rs.pcelinjak.entity.Apiary;
import rs.pcelinjak.entity.Harvest;
import rs.pcelinjak.entity.Hive;
import rs.pcelinjak.entity.Inspection;
import rs.pcelinjak.entity.Note;
import rs.pcelinjak.entity.Queen;
import rs.pcelinjak.entity.Reminder;
import rs.pcelinjak.entity.User;
import rs.pcelinjak.entity.WorkGroup;
import rs.pcelinjak.entity.WorkGroupHive;
import rs.pcelinjak.service.MailService;
import rs.pcelinjak.util.TokenUtil;

@Path("/auth")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthResource {

    @Inject
    JwtService jwtService;

    @Inject
    MailService mailService;

    @POST
    @Path("/register")
    @Transactional
    public Response register(AuthDto.RegisterRequest req) {
        if (req == null || isBlank(req.email) || isBlank(req.password) || isBlank(req.name) || isBlank(req.deviceUuid)) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Email, lozinka, ime i deviceUuid su obavezni.")).build();
        }
        String email = req.email.trim().toLowerCase();
        if (User.findByEmail(email) != null) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Korisnik sa ovim email-om već postoji.")).build();
        }
        User user = new User();
        user.email = email;
        user.passwordHash = BCrypt.withDefaults().hashToString(12, req.password.toCharArray());
        user.name = req.name.trim();
        user.phone = req.phone != null ? req.phone.trim() : null;
        user.boundDeviceUuid = null;
        user.activated = false;
        user.activationKey = TokenUtil.generateActivationKey();
        user.persist();

        mailService.sendActivationEmail(user);

        return Response.status(Response.Status.CREATED)
                .entity(new AuthDto.MessageResponse("Proverite email za aktivaciju naloga."))
                .build();
    }

    @POST
    @Path("/login")
    @Transactional
    public Response login(AuthDto.LoginRequest req) {
        if (req == null || isBlank(req.email) || isBlank(req.password) || isBlank(req.deviceUuid)) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Email, lozinka i deviceUuid su obavezni.")).build();
        }
        User user = User.findByEmail(req.email.trim().toLowerCase());
        if (user == null || !BCrypt.verifyer().verify(req.password.toCharArray(), user.passwordHash).verified) {
            return Response.status(401).entity(new AuthDto.MessageResponse("Pogrešan email ili lozinka.")).build();
        }
        if (!user.activated) {
            return Response.status(403).entity(new AuthDto.MessageResponse("Nalog nije aktiviran. Proverite email za aktivacioni link.")).build();
        }
        // New device takes over the account (single active phone).
        user.boundDeviceUuid = req.deviceUuid.trim();
        user.persist();
        return Response.ok(loginPayload(user)).build();
    }

    @GET
    @Path("/activate")
    @Produces(MediaType.TEXT_HTML)
    @Transactional
    public Response activateAccount(@QueryParam("key") String key) {
        if (key == null || key.isBlank()) {
            return Response.status(400).entity("<html><body><p>Neispravan aktivacioni link.</p></body></html>").build();
        }
        User user = User.findByActivationKey(key.trim());
        if (user == null) {
            return Response.status(404).entity("<html><body><p>Aktivacioni link nije validan ili je već iskorišćen.</p></body></html>").build();
        }
        user.activated = true;
        user.activationKey = null;
        user.persist();
        return Response.ok("""
            <!DOCTYPE html><html><head><meta charset="UTF-8"><title>Aktivacija</title></head><body>
            <h1>Nalog je aktiviran</h1>
            <p>Možete se sada prijaviti u aplikaciju Pčelinjak.</p>
            </body></html>
            """).build();
    }

    @POST
    @Path("/logout")
    @Transactional
    public Response logout(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);
        if (user != null) {
            user.boundDeviceUuid = null;
            user.persist();
        }
        return Response.ok(new AuthDto.MessageResponse("Odjavljeni ste.")).build();
    }

    @POST
    @Path("/delete-account")
    @Transactional
    public Response deleteAccount(AuthDto.DeleteAccountRequest req, @Context ContainerRequestContext ctx) {
        if (req == null || isBlank(req.password)) {
            return Response.status(400).entity(new AuthDto.MessageResponse("Lozinka je obavezna.")).build();
        }
        Long userId = (Long) ctx.getProperty("userId");
        User user = User.findById(userId);
        if (user == null) {
            return Response.status(404).entity(new AuthDto.MessageResponse("Korisnik nije pronađen.")).build();
        }
        if (!BCrypt.verifyer().verify(req.password.toCharArray(), user.passwordHash).verified) {
            return Response.status(401).entity(new AuthDto.MessageResponse("Pogrešna lozinka.")).build();
        }

        Reminder.delete("userId", userId);
        Inspection.delete("userId", userId);
        WorkGroupHive.delete("userId", userId);
        WorkGroup.delete("userId", userId);
        Harvest.delete("userId", userId);
        Note.delete("userId", userId);
        Queen.delete("userId", userId);
        Hive.delete("userId", userId);
        Apiary.delete("userId", userId);
        user.delete();

        return Response.ok(new AuthDto.MessageResponse("Nalog je obrisan.")).build();
    }

    private AuthDto.LoginResponse loginPayload(User user) {
        AuthDto.LoginResponse res = new AuthDto.LoginResponse();
        res.token = jwtService.createToken(user.id, user.email);
        res.userId = user.id;
        res.email = user.email;
        res.name = user.name;
        res.phone = user.phone;
        return res;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
