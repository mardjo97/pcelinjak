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
import rs.pcelinjak.entity.Note;

import java.util.List;

@Path("/api/notes")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class NoteResource {

    @GET
    @Path("/all")
    public List<SyncDtos.NoteItem> all(@Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        return Note.<Note>list("userId", userId).stream().map(this::toDto).toList();
    }

    @POST
    @Path("/sync")
    @Transactional
    public Response sync(List<SyncDtos.NoteItem> items, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        SyncDtos.SyncResponse<SyncDtos.NoteItem> res = new SyncDtos.SyncResponse<>();
        if (items != null) {
            for (SyncDtos.NoteItem item : items) {
                Note e = SyncSupport.upsert(userId, item, Note::findByUuid, Note::new, (n, d) -> {
                    n.hiveUuid = d.hiveUuid;
                    n.content = d.content;
                    n.groupType = d.groupType;
                    n.groupRecordUuid = d.groupRecordUuid;
                    n.reminderAt = d.reminderAt;
                });
                res.items.add(toDto(e));
            }
        }
        return Response.ok(res).build();
    }

    private SyncDtos.NoteItem toDto(Note n) {
        SyncDtos.NoteItem d = new SyncDtos.NoteItem();
        SyncSupport.copyMeta(n, d);
        d.hiveUuid = n.hiveUuid;
        d.content = n.content;
        d.groupType = n.groupType;
        d.groupRecordUuid = n.groupRecordUuid;
        d.reminderAt = n.reminderAt;
        return d;
    }
}
