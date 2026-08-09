package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "inspection")
public class Inspection extends SyncEntity {

    @Column(name = "hive_uuid", nullable = false, length = 36)
    public String hiveUuid;

    @Column(name = "inspected_at", nullable = false)
    public Instant inspectedAt;

    @Column(length = 2048)
    public String summary;

    @Column(name = "outcome_status", nullable = false, length = 32)
    public String outcomeStatus = "OK";

    @Column(name = "queen_status", nullable = false, length = 32)
    public String queenStatus = "NOT_CHECKED";

    @Column(name = "brood_status", nullable = false, length = 32)
    public String broodStatus = "NOT_CHECKED";

    @Column(name = "food_status", nullable = false, length = 32)
    public String foodStatus = "NOT_CHECKED";

    @Column(name = "temper_status", nullable = false, length = 32)
    public String temperStatus = "NOT_CHECKED";

    @Column(name = "health_status", nullable = false, length = 32)
    public String healthStatus = "NOT_CHECKED";

    @Column(name = "strength_status", nullable = false, length = 32)
    public String strengthStatus = "NOT_CHECKED";

    @Column(name = "follow_up_at")
    public Instant followUpAt;

    @Column(name = "source_type", length = 32)
    public String sourceType;

    @Column(name = "source_group_hive_uuid", length = 36)
    public String sourceGroupHiveUuid;

    @Column(name = "source_reminder_uuid", length = 36)
    public String sourceReminderUuid;

    public static Inspection findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }
}
