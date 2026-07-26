package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "apiary")
public class Apiary extends SyncEntity {

    @Column(nullable = false)
    public String name;

    @Column
    public String location;

    @Column(name = "work_number", nullable = false)
    public int workNumber;

    @Column(nullable = false, length = 20)
    public String color;

    @Column(name = "sort_order")
    public int sortOrder;

    /** Zvanični ID broj pčelinjaka (Prilog 4). */
    @Column(name = "official_id", length = 32)
    public String officialId;

    public static Apiary findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }
}
