package rs.pcelinjak.auth;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.Map;

@Provider
@Priority(Priorities.AUTHENTICATION)
@AdminSecured
public class AdminApiKeyFilter implements ContainerRequestFilter {

    public static final String ADMIN_KEY_HEADER = "X-Admin-Key";

    @ConfigProperty(name = "pcelinjak.admin-api-key", defaultValue = "")
    String adminApiKey;

    @Override
    public void filter(ContainerRequestContext requestContext) {
        if (adminApiKey == null || adminApiKey.isBlank()) {
            return;
        }
        String provided = requestContext.getHeaderString(ADMIN_KEY_HEADER);
        if (provided == null || !adminApiKey.equals(provided.trim())) {
            requestContext.abortWith(
                    Response.status(Response.Status.UNAUTHORIZED)
                            .entity(Map.of("error", "Invalid or missing X-Admin-Key"))
                            .build()
            );
        }
    }
}
