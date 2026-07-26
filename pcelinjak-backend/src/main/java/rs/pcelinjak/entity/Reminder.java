package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "reminder")
public class Reminder extends SyncEntity {

    @Column(name = "hive_uuid", length = 36)
    public String hiveUuid;

    @Column(name = "group_hive_uuid", length = 36)
    public String groupHiveUuid;

    @Column(name = "due_at", nullable = false)
    public Instant dueAt;

    @Column(nullable = false, length = 256)
    public String title;

    @Column(nullable = false)
    public boolean completed = false;

    public static Reminder findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }
}
