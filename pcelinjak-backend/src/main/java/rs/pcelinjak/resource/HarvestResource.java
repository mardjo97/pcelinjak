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
import rs.pcelinjak.entity.Harvest;

import java.util.List;

@Path("/api/harvests")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class HarvestResource {

    @GET
    @Path("/all")
    public List<SyncDtos.HarvestItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Harvest.<Harvest>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.HarvestItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.HarvestItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.HarvestItem item : items) {
                Harvest e = SyncSupport.upsert(userId, item, Harvest::findByUuid, Harvest::new, (h, d) -> {
                    h.hiveUuid = d.hiveUuid;
                    h.pastureType = d.pastureType;
                    h.amountKg = d.amountKg;
                    h.collectedAt = d.collectedAt;
                    h.harvestYear = d.harvestYear;
                    h.workGroupHiveUuid = d.workGroupHiveUuid;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.HarvestItem toDto(Harvest h) {
        SyncDtos.HarvestItem d = new SyncDtos.HarvestItem();
        SyncSupport.copyMeta(h, d);
        d.hiveUuid = h.hiveUuid;
        d.pastureType = h.pastureType;
        d.amountKg = h.amountKg;
        d.collectedAt = h.collectedAt;
        d.harvestYear = h.harvestYear;
        d.workGroupHiveUuid = h.workGroupHiveUuid;
        return d;
    }
}
