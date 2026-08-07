package rs.pcelinjak.resource;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import rs.pcelinjak.auth.AdminSecured;
import rs.pcelinjak.entity.Apiary;
import rs.pcelinjak.entity.Feedback;
import rs.pcelinjak.entity.Harvest;
import rs.pcelinjak.entity.Hive;
import rs.pcelinjak.entity.Inspection;
import rs.pcelinjak.entity.Note;
import rs.pcelinjak.entity.Queen;
import rs.pcelinjak.entity.Reminder;
import rs.pcelinjak.entity.User;
import rs.pcelinjak.entity.WorkGroup;
import rs.pcelinjak.entity.WorkGroupHive;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Ops-dashboard metrics: GET /admin/stats (optional X-Admin-Key when pcelinjak.admin-api-key is set).
 */
@Path("/admin/stats")
@Produces(MediaType.APPLICATION_JSON)
@AdminSecured
public class AdminStatsResource {

    @GET
    public Map<String, Object> stats() {
        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("users", User.count());
        stats.put("usersActivated", User.count("activated", true));
        stats.put("apiaries", Apiary.count("dateDeleted is null"));
        stats.put("hives", Hive.count("dateDeleted is null"));
        stats.put("hivesActive", Hive.count("dateDeleted is null and status = ?1", "ACTIVE"));
        stats.put("queens", Queen.count("dateDeleted is null"));
        stats.put("queensActive", Queen.count("dateDeleted is null and active = true"));
        stats.put("inspections", Inspection.count("dateDeleted is null"));
        stats.put("harvests", Harvest.count("dateDeleted is null"));
        stats.put("notes", Note.count("dateDeleted is null"));
        stats.put("reminders", Reminder.count("dateDeleted is null"));
        stats.put("remindersOpen", Reminder.count("dateDeleted is null and completed = false"));
        stats.put("workGroups", WorkGroup.count("dateDeleted is null"));
        stats.put("workGroupHives", WorkGroupHive.count("dateDeleted is null"));
        stats.put("feedback", Feedback.count());
        return stats;
    }
}
