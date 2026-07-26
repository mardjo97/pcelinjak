package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "hive")
public class Hive extends SyncEntity {

    @Column(nullable = false, length = 64)
    public String barcode;

    @Column(name = "order_number", nullable = false)
    public int orderNumber;

    @Column(name = "hive_type", nullable = false, length = 32)
    public String hiveType;

    @Column(name = "apiary_uuid", nullable = false, length = 36)
    public String apiaryUuid;

    @Column(length = 512)
    public String description;

    /** ACTIVE, ARCHIVED, DEAD */
    @Column(nullable = false, length = 20)
    public String status = "ACTIVE";

    public static Hive findByUuid(String uuid) {
        return find("uuid", uuid).firstResult();
    }

    public static Hive findByUserAndBarcode(Long userId, String barcode) {
        return find("userId = ?1 and barcode = ?2 and dateDeleted is null", userId, barcode).firstResult();
    }
}
