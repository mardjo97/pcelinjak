package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "harvest")
public class Harvest extends SyncEntity {

    @Column(name = "hive_uuid", nullable = false, length = 36)
    public String hiveUuid;

    @Column(name = "pasture_type", nullable = false, length = 64)
    public String pastureType;

    @Column(name = "amount_kg", nullable = false)
    public double amountKg;

    @Column(name = "collected_at")
    public Instant collectedAt;

    @Column(name = "harvest_year", nullable = false)
    public int harvestYear;

    /** Veza sa članstvom u grupi (MOVED / GOOD_PASTURE). */
    @Column(name = "work_group_hive_uuid", length = 36)
    public String workGroupHiveUuid;

    public static Harvest findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }
}
