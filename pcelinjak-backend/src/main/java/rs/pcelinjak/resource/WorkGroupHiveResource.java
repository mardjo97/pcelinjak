package rs.pcelinjak.resource;

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
import rs.pcelinjak.entity.WorkGroupHive;

import java.util.List;

@Path("/api/work-group-hives")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class WorkGroupHiveResource {

    @GET
    @Path("/all")
    public List<SyncDtos.WorkGroupHiveItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return WorkGroupHive.<WorkGroupHive>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.WorkGroupHiveItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.WorkGroupHiveItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.WorkGroupHiveItem item : items) {
                WorkGroupHive e = SyncSupport.upsert(userId, item, WorkGroupHive::findByUuid, WorkGroupHive::new, (g, d) -> {
                    g.groupUuid = d.groupUuid;
                    g.hiveUuid = d.hiveUuid;
                    g.amount = d.amount;
                    g.note = d.note;
                    g.checkDate = d.checkDate;
                    g.reminderAt = d.reminderAt;
                    g.pastureType = d.pastureType;
                    g.locationName = d.locationName;
                    String status = d.membershipStatus;
                    if (status == null || status.isBlank()) {
                        status = d.done ? "FINISHED" : "ACTIVE";
                    }
                    g.membershipStatus = status;
                    g.done = !"ACTIVE".equals(status);
                    g.activeFrom = d.activeFrom != null ? d.activeFrom : g.activeFrom;
                    if (g.activeFrom == null) {
                        g.activeFrom = g.dateCreated;
                    }
                    g.activeTo = d.activeTo;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.WorkGroupHiveItem toDto(WorkGroupHive g) {
        SyncDtos.WorkGroupHiveItem d = new SyncDtos.WorkGroupHiveItem();
        SyncSupport.copyMeta(g, d);
        d.groupUuid = g.groupUuid;
        d.hiveUuid = g.hiveUuid;
        d.amount = g.amount;
        d.note = g.note;
        d.checkDate = g.checkDate;
        d.reminderAt = g.reminderAt;
        d.pastureType = g.pastureType;
        d.locationName = g.locationName;
        d.membershipStatus = g.membershipStatus != null ? g.membershipStatus : (g.done ? "FINISHED" : "ACTIVE");
        d.done = !"ACTIVE".equals(d.membershipStatus);
        d.activeFrom = g.activeFrom;
        d.activeTo = g.activeTo;
        return d;
    }
}
