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
}
