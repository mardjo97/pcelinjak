package rs.pcelinjak.auth;

import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import rs.pcelinjak.entity.User;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@Provider
public class AuthFilter implements ContainerRequestFilter {

    public static final String DEVICE_HEADER = "X-Device-Id";

    private static final List<String> SKIP_PATHS = List.of(
            "/auth/register", "auth/register",
            "/auth/login", "auth/login",
            "/auth/activate", "auth/activate",
            "/api/ping", "api/ping",
            "/admin/stats", "admin/stats");

    @Inject
    JwtService jwtService;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        String path = requestContext.getUriInfo().getPath();
        if (SKIP_PATHS.stream().anyMatch(path::startsWith)) {
            return;
        }
        if ("OPTIONS".equalsIgnoreCase(requestContext.getMethod())) {
            return;
        }

        String auth = requestContext.getHeaderString("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED).build());
            return;
        }
        String token = auth.substring(7);
        if (!jwtService.isValid(token)) {
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED).build());
            return;
        }

        Long userId = jwtService.getUserIdFromToken(token);
        User user = User.findById(userId);
        if (user == null) {
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED).build());
            return;
        }

        String deviceId = requestContext.getHeaderString(DEVICE_HEADER);
        if (deviceId == null || deviceId.isBlank()
                || user.boundDeviceUuid == null
                || !user.boundDeviceUuid.equals(deviceId.trim())) {
            requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED)
                    .type(MediaType.APPLICATION_JSON)
                    .entity(Map.of("code", "DEVICE_MISMATCH", "message", "Nalog je aktivan na drugom uređaju."))
                    .build());
            return;
        }

        requestContext.setProperty("userId", userId);
        requestContext.setProperty("deviceUuid", deviceId.trim());
    }
}
