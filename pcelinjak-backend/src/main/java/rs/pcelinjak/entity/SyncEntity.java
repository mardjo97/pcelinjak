package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;

import java.time.Instant;

@MappedSuperclass
public abstract class SyncEntity extends PcelinjakEntity {

    @Column(nullable = false, unique = true, length = 36)
    public String uuid;

    @Column(name = "user_id", nullable = false)
    public Long userId;

    @Column(name = "date_synched")
    public Instant dateSynched;

    @Column(name = "date_deleted")
    public Instant dateDeleted;
}
