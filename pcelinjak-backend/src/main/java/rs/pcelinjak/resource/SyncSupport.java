package rs.pcelinjak.resource;

import io.quarkus.hibernate.orm.panache.Panache;
import rs.pcelinjak.dto.SyncDtos;
import rs.pcelinjak.entity.SyncEntity;

import java.time.Instant;
import java.util.function.BiConsumer;
import java.util.function.Function;
import java.util.function.Supplier;

final class SyncSupport {

    private SyncSupport() {
    }

    static void copyMeta(SyncEntity e, SyncDtos.SyncMeta m) {
        m.uuid = e.uuid;
        m.dateCreated = e.dateCreated;
        m.dateModified = e.dateModified;
        m.dateSynched = e.dateSynched;
        m.dateDeleted = e.dateDeleted;
    }

    static <E extends SyncEntity, D extends SyncDtos.SyncMeta> E upsert(
            Long userId,
            D item,
            Function<String, E> findByUuid,
            Supplier<E> factory,
            BiConsumer<E, D> applyFields) {
        if (item == null || item.uuid == null || item.uuid.isBlank()) {
            throw new IllegalArgumentException("uuid je obavezan");
        }
        E entity = findByUuid.apply(item.uuid);
        if (entity == null) {
            entity = factory.get();
            entity.uuid = item.uuid.trim();
            entity.userId = userId;
            if (item.dateCreated != null) {
                entity.dateCreated = item.dateCreated;
            }
        } else if (!entity.userId.equals(userId)) {
            throw new IllegalArgumentException("Zapis pripada drugom korisniku");
        }
        applyFields.accept(entity, item);
        entity.dateDeleted = item.dateDeleted;
        if (item.dateModified != null) {
            entity.dateModified = item.dateModified;
        }
        entity.persist();
        // Flush da @UpdateTimestamp prvo upiše dateModified, pa tek onda dateSynched.
        Panache.getEntityManager().flush();
        Instant synched = Instant.now();
        if (entity.dateModified != null && synched.isBefore(entity.dateModified)) {
            synched = entity.dateModified;
        }
        entity.dateSynched = synched;
        return entity;
    }
}
