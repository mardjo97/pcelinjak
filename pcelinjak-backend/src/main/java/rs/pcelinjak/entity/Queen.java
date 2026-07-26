package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "queen")
public class Queen extends SyncEntity {

    @Column(name = "hive_uuid", nullable = false, length = 36)
    public String hiveUuid;

    @Column(name = "queen_year")
    public Integer queenYear;

    @Column(nullable = false)
    public boolean marked;

    @Column(length = 128)
    public String origin;

    @Column(name = "active_from")
    public Instant activeFrom;

    @Column(name = "active_to")
    public Instant activeTo;

    @Column(nullable = false)
    public boolean active = true;

    @Column(name = "end_reason", length = 40)
    public String endReason;

    public static Queen findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }

    public static Queen findActiveByHive(Long userId, String hiveUuid) {
        return find("userId = ?1 and hiveUuid = ?2 and active = true and dateDeleted is null", userId, hiveUuid)
                .firstResult();
    }
}
