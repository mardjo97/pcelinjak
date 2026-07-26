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
import rs.pcelinjak.entity.Hive;

import java.util.List;

@Path("/api/hives")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class HiveResource {

    @GET
    @Path("/all")
    public List<SyncDtos.HiveItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Hive.<Hive>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.HiveItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.HiveItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.HiveItem item : items) {
                Hive e = SyncSupport.upsert(userId, item, Hive::findByUuid, Hive::new, (h, d) -> {
                    h.barcode = d.barcode;
                    h.orderNumber = d.orderNumber;
                    h.hiveType = d.hiveType;
                    h.apiaryUuid = d.apiaryUuid;
                    h.description = d.description;
                    h.status = (d.status == null || d.status.isBlank()) ? "ACTIVE" : d.status;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.HiveItem toDto(Hive h) {
        SyncDtos.HiveItem d = new SyncDtos.HiveItem();
        SyncSupport.copyMeta(h, d);
        d.barcode = h.barcode;
        d.orderNumber = h.orderNumber;
        d.hiveType = h.hiveType;
        d.apiaryUuid = h.apiaryUuid;
        d.description = h.description;
        d.status = h.status != null ? h.status : "ACTIVE";
        return d;
    }
}
