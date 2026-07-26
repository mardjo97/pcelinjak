package rs.pcelinjak.notification;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** HTTP klijent ka shared notification-service (X-Api-Key). */
@ApplicationScoped
public class NotificationClient {

    private static final Logger LOG = Logger.getLogger(NotificationClient.class);

    @ConfigProperty(name = "notification.service.url", defaultValue = "http://localhost:8085")
    String baseUrl;

    @ConfigProperty(name = "notification.api-key", defaultValue = "")
    Optional<String> apiKey;

    @ConfigProperty(name = "notification.enabled", defaultValue = "true")
    boolean enabled;

    private HttpClient http;
    private ObjectMapper mapper;

    @PostConstruct
    void init() {
        http = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        mapper = new ObjectMapper()
                .registerModule(new JavaTimeModule())
                .findAndRegisterModules();
    }

    public boolean isConfigured() {
        return enabled && apiKey.isPresent() && !apiKey.get().isBlank();
    }

    public boolean upsertDevice(String externalUserId, String deviceId, String fcmToken) {
        Optional<String> body = exchangeRaw("PUT", "/devices", Map.of(
                "externalUserId", externalUserId,
                "deviceId", deviceId,
                "fcmToken", fcmToken
        ));
        return body.isPresent();
    }

    public Optional<NotificationDto> createReminder(
            String externalUserId,
            String title,
            String body,
            Instant scheduledAt,
            Map<String, String> data
    ) {
        return exchangeJson("POST", "/notifications/reminders", Map.of(
                "externalUserId", externalUserId,
                "title", title,
                "body", body,
                "scheduledAt", scheduledAt.toString(),
                "data", data == null ? Map.of() : data
        ), NotificationDto.class);
    }

    public Optional<NotificationDto> createInstant(
            String externalUserId,
            String title,
            String body,
            Map<String, String> data
    ) {
        return exchangeJson("POST", "/notifications/instant", Map.of(
                "externalUserId", externalUserId,
                "title", title,
                "body", body,
                "data", data == null ? Map.of() : data
        ), NotificationDto.class);
    }

    public Optional<NotificationDto> reschedule(String notificationId, Instant scheduledAt) {
        return exchangeJson("PATCH", "/notifications/" + notificationId,
                Map.of("scheduledAt", scheduledAt.toString()), NotificationDto.class);
    }

    public Optional<NotificationDto> cancel(String notificationId) {
        return exchangeJson("DELETE", "/notifications/" + notificationId, null, NotificationDto.class);
    }

    private <T> Optional<T> exchangeJson(String method, String path, Object body, Class<T> type) {
        return exchangeRaw(method, path, body).flatMap(raw -> {
            try {
                if (raw.isBlank()) {
                    return Optional.empty();
                }
                T dto = mapper.readValue(raw, type);
                if (dto instanceof NotificationDto n && n.failureReason != null) {
                    LOG.warnf("Notification %s failureReason=%s status=%s", n.id, n.failureReason, n.status);
                }
                return Optional.of(dto);
            } catch (Exception e) {
                LOG.warnf(e, "Neuspelo parsiranje notification response: %s", raw);
                return Optional.empty();
            }
        });
    }

    private Optional<String> exchangeRaw(String method, String path, Object body) {
        if (!isConfigured()) {
            LOG.debugf("Notification service nije konfigurisan — skip %s %s", method, path);
            return Optional.empty();
        }
        int attempts = 0;
        while (attempts < 2) {
            attempts++;
            try {
                HttpRequest.Builder b = HttpRequest.newBuilder()
                        .uri(URI.create(trimSlash(baseUrl) + path))
                        .timeout(Duration.ofSeconds(10))
                        .header("X-Api-Key", apiKey.get())
                        .header("Accept", "application/json");
                if (body != null) {
                    b.header("Content-Type", "application/json");
                    b.method(method, HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body)));
                } else {
                    b.method(method, HttpRequest.BodyPublishers.noBody());
                }
                HttpResponse<String> res = http.send(b.build(), HttpResponse.BodyHandlers.ofString());
                if (res.statusCode() >= 200 && res.statusCode() < 300) {
                    return Optional.ofNullable(res.body() == null ? "" : res.body());
                }
                LOG.warnf("Notification %s %s → HTTP %s body=%s", method, path, res.statusCode(), res.body());
                if (res.statusCode() >= 500 && attempts < 2) {
                    continue;
                }
                return Optional.empty();
            } catch (Exception e) {
                LOG.warnf(e, "Notification %s %s failed (attempt %s)", method, path, attempts);
                if (attempts >= 2) {
                    return Optional.empty();
                }
            }
        }
        return Optional.empty();
    }

    private static String trimSlash(String url) {
        return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class NotificationDto {
        public String id;
        public String externalUserId;
        public String type;
        public String title;
        public String body;
        public Instant scheduledAt;
        public Instant sentAt;
        public String status;
        public String failureReason;
        public List<InvalidDevice> invalidDevices;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class InvalidDevice {
        public String id;
        public String deviceId;
        public String status;
        public String externalUserId;
    }
}
