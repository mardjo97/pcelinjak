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
import rs.pcelinjak.entity.Apiary;

import java.util.List;

@Path("/api/apiaries")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ApiaryResource {

    @GET
    @Path("/all")
    public List<SyncDtos.ApiaryItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Apiary.<Apiary>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.ApiaryItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.ApiaryItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.ApiaryItem item : items) {
                Apiary e = SyncSupport.upsert(userId, item, Apiary::findByUuid, Apiary::new, (a, d) -> {
                    a.name = d.name;
                    a.location = d.location;
                    a.workNumber = d.workNumber;
                    a.color = d.color;
                    a.sortOrder = d.sortOrder;
                    a.officialId = d.officialId;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.ApiaryItem toDto(Apiary a) {
        SyncDtos.ApiaryItem d = new SyncDtos.ApiaryItem();
        SyncSupport.copyMeta(a, d);
        d.name = a.name;
        d.location = a.location;
        d.workNumber = a.workNumber;
        d.color = a.color;
        d.sortOrder = a.sortOrder;
        d.officialId = a.officialId;
        return d;
    }
}
