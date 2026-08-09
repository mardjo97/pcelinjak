package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "work_group")
public class WorkGroup extends SyncEntity {

    /** MOVED, GOOD_PASTURE, QUEEN_CHANGE, CONTROL, FEEDING, REPRODUCTION */
    @Column(name = "group_type", nullable = false, length = 40)
    public String groupType;

    @Column(name = "pasture_type", length = 64)
    public String pastureType;

    @Column(name = "location_name", length = 128)
    public String locationName;

    @Column(nullable = false)
    public boolean finished = false;

    public static WorkGroup findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }

    /** Aktivna (nesbrisana) grupa datog tipa za korisnika — najviše jedna. */
    public static WorkGroup findActiveByUserAndType(Long userId, String groupType) {
        if (userId == null || groupType == null || groupType.isBlank()) {
            return null;
        }
        return find(
                "userId = ?1 and groupType = ?2 and dateDeleted is null",
                userId,
                groupType.trim()
        ).firstResult();
    }
}
