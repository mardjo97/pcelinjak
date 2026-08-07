package rs.pcelinjak.resource;

import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import rs.pcelinjak.dto.SyncDtos;
import rs.pcelinjak.entity.Reminder;
import rs.pcelinjak.notification.ReminderPushService;

import java.util.List;

@Path("/api/reminders")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ReminderResource {

    @Inject
    ReminderPushService reminderPushService;

    @GET
    @Path("/all")
    public List<SyncDtos.ReminderItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Reminder.<Reminder>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.ReminderItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.ReminderItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.ReminderItem item : items) {
                Reminder e = SyncSupport.upsert(userId, item, Reminder::findByUuid, Reminder::new, (r, d) -> {
                    r.hiveUuid = d.hiveUuid;
                    r.groupHiveUuid = d.groupHiveUuid;
                    r.inspectionUuid = d.inspectionUuid;
                    r.dueAt = d.dueAt;
                    r.title = d.title;
                    r.completed = d.completed;
                });
                reminderPushService.syncReminder(e);
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.ReminderItem toDto(Reminder r) {
        SyncDtos.ReminderItem d = new SyncDtos.ReminderItem();
        SyncSupport.copyMeta(r, d);
        d.hiveUuid = r.hiveUuid;
        d.groupHiveUuid = r.groupHiveUuid;
        d.inspectionUuid = r.inspectionUuid;
        d.dueAt = r.dueAt;
        d.title = r.title;
        d.completed = r.completed;
        return d;
    }
}
