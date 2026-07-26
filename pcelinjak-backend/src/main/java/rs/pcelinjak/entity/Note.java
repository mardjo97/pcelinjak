package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.time.Instant;

@Entity
@Table(name = "note")
public class Note extends SyncEntity {

    @Column(name = "hive_uuid", nullable = false, length = 36)
    public String hiveUuid;

    @Column(nullable = false, length = 4000)
    public String content;

    @Column(name = "group_type", length = 40)
    public String groupType;

    @Column(name = "group_record_uuid", length = 36)
    public String groupRecordUuid;

    @Column(name = "reminder_at")
    public Instant reminderAt;

    public static Note findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }
}
