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
import rs.pcelinjak.entity.WorkGroup;

import java.util.List;

@Path("/api/work-groups")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class WorkGroupResource {

    @GET
    @Path("/all")
    public List<SyncDtos.WorkGroupItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return WorkGroup.<WorkGroup>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.WorkGroupItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.WorkGroupItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.WorkGroupItem item : items) {
                WorkGroup e = SyncSupport.upsert(userId, item, WorkGroup::findByUuid, WorkGroup::new, (g, d) -> {
                    g.groupType = d.groupType;
                    g.pastureType = d.pastureType;
                    g.locationName = d.locationName;
                    g.finished = d.finished;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.WorkGroupItem toDto(WorkGroup g) {
        SyncDtos.WorkGroupItem d = new SyncDtos.WorkGroupItem();
        SyncSupport.copyMeta(g, d);
        d.groupType = g.groupType;
        d.pastureType = g.pastureType;
        d.locationName = g.locationName;
        d.finished = g.finished;
        return d;
    }
}
