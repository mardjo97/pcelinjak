package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "work_group_hive")
public class WorkGroupHive extends SyncEntity {

    @Column(name = "group_uuid", nullable = false, length = 36)
    public String groupUuid;

    @Column(name = "hive_uuid", nullable = false, length = 36)
    public String hiveUuid;

    @Column
    public Double amount;

    @Column(length = 2000)
    public String note;

    @Column(name = "check_date")
    public Instant checkDate;

    @Column(name = "reminder_at")
    public Instant reminderAt;

    @Column(name = "pasture_type", length = 80)
    public String pastureType;

    @Column(name = "location_name", length = 200)
    public String locationName;

    /** Legacy flag; keep in sync with membershipStatus != ACTIVE */
    @Column(nullable = false)
    public boolean done = false;

    /** ACTIVE, FINISHED, REMOVED */
    @Column(name = "membership_status", nullable = false, length = 20)
    public String membershipStatus = "ACTIVE";

    @Column(name = "active_from")
    public Instant activeFrom;

    @Column(name = "active_to")
    public Instant activeTo;

    public static WorkGroupHive findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }
}
