package rs.pcelinjak.resource;

import jakarta.transaction.Transactional;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import rs.pcelinjak.auth.AdminSecured;
import rs.pcelinjak.entity.Feedback;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Ops inbox: GET /admin/feedback (same X-Admin-Key as /admin/stats).
 */
@Path("/admin/feedback")
@Produces(MediaType.APPLICATION_JSON)
@AdminSecured
public class AdminFeedbackResource {

    @GET
    @Transactional
    public Map<String, Object> list() {
        List<Feedback> rows = Feedback.find("ORDER BY dateCreated DESC").page(0, 100).list();
        List<Map<String, Object>> items = rows.stream().map(f -> {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", f.id);
            row.put("createdAt", f.dateCreated != null ? f.dateCreated.toString() : null);
            row.put("email", f.email);
            row.put("message", f.message);
            row.put("appVersion", f.appVersion);
            row.put("locale", f.locale);
            return row;
        }).toList();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("count", Feedback.count());
        body.put("items", items);
        body.put("generatedAt", Instant.now().toString());
        return body;
    }
}
