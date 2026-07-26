package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "users")
public class User extends PcelinjakEntity {

    @Column(nullable = false, unique = true)
    public String email;

    @Column(nullable = false)
    public String passwordHash;

    @Column(nullable = false)
    public String name;

    @Column
    public String phone;

    @Column(name = "bound_device_uuid", length = 36)
    public String boundDeviceUuid;

    @Column(nullable = false)
    public boolean activated = false;

    @Column(name = "activation_key", length = 20)
    public String activationKey;

    @Column(name = "needs_fcm_refresh", nullable = false)
    public boolean needsFcmRefresh = false;

    public static User findByEmail(String email) {
        return find("email", email).firstResult();
    }

    public static User findByActivationKey(String key) {
        return find("activationKey", key).firstResult();
    }
}
