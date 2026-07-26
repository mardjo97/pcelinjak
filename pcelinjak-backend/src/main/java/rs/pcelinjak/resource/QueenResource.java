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
import rs.pcelinjak.entity.Queen;

import java.util.List;

@Path("/api/queens")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class QueenResource {

    @GET
    @Path("/all")
    public List<SyncDtos.QueenItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Queen.<Queen>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.QueenItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.QueenItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.QueenItem item : items) {
                Queen e = SyncSupport.upsert(userId, item, Queen::findByUuid, Queen::new, (q, d) -> {
                    q.hiveUuid = d.hiveUuid;
                    q.queenYear = d.queenYear;
                    q.marked = d.marked;
                    q.origin = d.origin;
                    q.activeFrom = d.activeFrom;
                    q.activeTo = d.activeTo;
                    q.active = d.active;
                    q.endReason = d.endReason;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.QueenItem toDto(Queen q) {
        SyncDtos.QueenItem d = new SyncDtos.QueenItem();
        SyncSupport.copyMeta(q, d);
        d.hiveUuid = q.hiveUuid;
        d.queenYear = q.queenYear;
        d.marked = q.marked;
        d.origin = q.origin;
        d.activeFrom = q.activeFrom;
        d.activeTo = q.activeTo;
        d.active = q.active;
        d.endReason = q.endReason;
        return d;
    }
}
