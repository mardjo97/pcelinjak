package rs.pcelinjak.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "feedback")
public class Feedback extends PcelinjakEntity {

    @Column(name = "user_id")
    public Long userId;

    @Column(length = 200)
    public String email;

    @Column(nullable = false, length = 4000)
    public String message;

    @Column(name = "app_version", length = 40)
    public String appVersion;

    @Column(length = 16)
    public String locale;
}
