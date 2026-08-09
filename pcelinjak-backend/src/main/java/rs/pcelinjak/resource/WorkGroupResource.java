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
import rs.pcelinjak.entity.WorkGroupHive;

import java.time.Instant;
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
                res.items.add(toDto(upsertWorkGroup(userId, item)));
            }
        }
        return Response.ok(res).build();
    }

    /**
     * Jedan aktivan tip grupe po korisniku. Novi UUID za postojeći tip
     * se spaja u kanonsku grupu (članstva se prebacuju).
     */
    private WorkGroup upsertWorkGroup(Long userId, SyncDtos.WorkGroupItem item) {
        if (item == null || item.uuid == null || item.uuid.isBlank()) {
            throw new IllegalArgumentException("uuid je obavezan");
        }
        String incomingUuid = item.uuid.trim();
        boolean softDelete = item.dateDeleted != null;

        if (!softDelete && item.groupType != null && !item.groupType.isBlank()) {
            WorkGroup byType = WorkGroup.findActiveByUserAndType(userId, item.groupType);
            WorkGroup byUuid = WorkGroup.findByUuid(incomingUuid);

            if (byType != null && (byUuid == null || !byUuid.uuid.equals(byType.uuid))) {
                if (byUuid != null) {
                    remapMemberships(byUuid.uuid, byType.uuid);
                    byUuid.dateDeleted = Instant.now();
                    byUuid.persist();
                } else {
                    remapMemberships(incomingUuid, byType.uuid);
                }
                SyncDtos.WorkGroupItem canonical = copyWithUuid(item, byType.uuid);
                canonical.dateDeleted = null;
                return SyncSupport.upsert(
                        userId,
                        canonical,
                        WorkGroup::findByUuid,
                        WorkGroup::new,
                        this::applyFields
                );
            }
        }

        return SyncSupport.upsert(
                userId,
                item,
                WorkGroup::findByUuid,
                WorkGroup::new,
                this::applyFields
        );
    }

    private static SyncDtos.WorkGroupItem copyWithUuid(SyncDtos.WorkGroupItem src, String uuid) {
        SyncDtos.WorkGroupItem d = new SyncDtos.WorkGroupItem();
        d.uuid = uuid;
        d.dateCreated = src.dateCreated;
        d.dateModified = src.dateModified;
        d.dateSynched = src.dateSynched;
        d.dateDeleted = src.dateDeleted;
        d.groupType = src.groupType;
        d.pastureType = src.pastureType;
        d.locationName = src.locationName;
        d.finished = src.finished;
        return d;
    }

    private void applyFields(WorkGroup g, SyncDtos.WorkGroupItem d) {
        g.groupType = d.groupType;
        g.pastureType = d.pastureType;
        g.locationName = d.locationName;
        g.finished = d.finished;
    }

    private static void remapMemberships(String fromGroupUuid, String toGroupUuid) {
        if (fromGroupUuid == null || toGroupUuid == null || fromGroupUuid.equals(toGroupUuid)) {
            return;
        }
        WorkGroupHive.update(
                "groupUuid = ?1, dateModified = ?2 where groupUuid = ?3 and dateDeleted is null",
                toGroupUuid,
                Instant.now(),
                fromGroupUuid
        );
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
