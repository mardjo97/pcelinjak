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
import rs.pcelinjak.entity.Inspection;

import java.util.List;

@Path("/api/inspections")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class InspectionResource {

    @GET
    @Path("/all")
    public List<SyncDtos.InspectionItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Inspection.<Inspection>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.InspectionItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.InspectionItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.InspectionItem item : items) {
                Inspection e = SyncSupport.upsert(userId, item, Inspection::findByUuid, Inspection::new, (i, d) -> {
                    i.hiveUuid = d.hiveUuid;
                    i.inspectedAt = d.inspectedAt;
                    i.summary = d.summary;
                    i.outcomeStatus = d.outcomeStatus == null || d.outcomeStatus.isBlank() ? "OK" : d.outcomeStatus;
                    i.queenStatus = d.queenStatus == null || d.queenStatus.isBlank() ? "NOT_CHECKED" : d.queenStatus;
                    i.broodStatus = d.broodStatus == null || d.broodStatus.isBlank() ? "NOT_CHECKED" : d.broodStatus;
                    i.foodStatus = d.foodStatus == null || d.foodStatus.isBlank() ? "NOT_CHECKED" : d.foodStatus;
                    i.temperStatus = normalizeTemper(d.temperStatus);
                    i.healthStatus = d.healthStatus == null || d.healthStatus.isBlank() ? "NOT_CHECKED" : d.healthStatus;
                    i.strengthStatus = d.strengthStatus == null || d.strengthStatus.isBlank() ? "NOT_CHECKED" : d.strengthStatus;
                    i.followUpAt = d.followUpAt;
                    i.sourceType = d.sourceType;
                    i.sourceGroupHiveUuid = d.sourceGroupHiveUuid;
                    i.sourceReminderUuid = d.sourceReminderUuid;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.InspectionItem toDto(Inspection i) {
        SyncDtos.InspectionItem d = new SyncDtos.InspectionItem();
        SyncSupport.copyMeta(i, d);
        d.hiveUuid = i.hiveUuid;
        d.inspectedAt = i.inspectedAt;
        d.summary = i.summary;
        d.outcomeStatus = i.outcomeStatus;
        d.queenStatus = i.queenStatus;
        d.broodStatus = i.broodStatus;
        d.foodStatus = i.foodStatus;
        d.temperStatus = i.temperStatus;
        d.healthStatus = i.healthStatus;
        d.strengthStatus = i.strengthStatus;
        d.followUpAt = i.followUpAt;
        d.sourceType = i.sourceType;
        d.sourceGroupHiveUuid = i.sourceGroupHiveUuid;
        d.sourceReminderUuid = i.sourceReminderUuid;
        return d;
    }

    private static String normalizeTemper(String temperStatus) {
        if (temperStatus == null || temperStatus.isBlank()) {
            return "NOT_CHECKED";
        }
        return switch (temperStatus) {
            case "GOOD" -> "CALM";
            case "ATTENTION" -> "NERVOUS";
            case "CRITICAL" -> "AGGRESSIVE";
            default -> temperStatus;
        };
    }
}
