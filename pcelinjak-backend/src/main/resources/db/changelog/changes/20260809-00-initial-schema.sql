-- Full baseline schema for Pčelinjak (MySQL 8+).
-- Assumes empty database (drop & recreate DB, then start backend).

CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    email VARCHAR(255) NOT NULL,
    passwordHash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(255) NULL,
    bound_device_uuid VARCHAR(36) NULL,
    activated TINYINT(1) NOT NULL DEFAULT 0,
    activation_key VARCHAR(20) NULL,
    needs_fcm_refresh TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY UK_users_email (email)
);

CREATE TABLE feedback (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    user_id BIGINT NULL,
    email VARCHAR(200) NULL,
    message VARCHAR(4000) NOT NULL,
    app_version VARCHAR(40) NULL,
    locale VARCHAR(16) NULL,
    PRIMARY KEY (id)
);

CREATE TABLE apiary (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NULL,
    work_number INT NOT NULL,
    color VARCHAR(20) NOT NULL,
    sort_order INT NULL,
    official_id VARCHAR(32) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_apiary_uuid (uuid)
);

CREATE TABLE hive (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    barcode VARCHAR(64) NOT NULL,
    order_number INT NOT NULL,
    hive_type VARCHAR(32) NOT NULL,
    apiary_uuid VARCHAR(36) NOT NULL,
    description VARCHAR(512) NULL,
    status VARCHAR(20) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_hive_uuid (uuid)
);

CREATE TABLE queen (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    hive_uuid VARCHAR(36) NOT NULL,
    queen_year INT NULL,
    marked TINYINT(1) NOT NULL,
    origin VARCHAR(128) NULL,
    active_from DATETIME(6) NULL,
    active_to DATETIME(6) NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    end_reason VARCHAR(40) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_queen_uuid (uuid)
);

CREATE TABLE note (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    hive_uuid VARCHAR(36) NOT NULL,
    content VARCHAR(4000) NOT NULL,
    group_type VARCHAR(40) NULL,
    group_record_uuid VARCHAR(36) NULL,
    reminder_at DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_note_uuid (uuid)
);

CREATE TABLE harvest (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    hive_uuid VARCHAR(36) NOT NULL,
    pasture_type VARCHAR(64) NOT NULL,
    amount_kg DOUBLE NOT NULL,
    collected_at DATETIME(6) NULL,
    harvest_year INT NOT NULL,
    work_group_hive_uuid VARCHAR(36) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_harvest_uuid (uuid)
);

CREATE TABLE inspection (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    hive_uuid VARCHAR(36) NOT NULL,
    inspected_at DATETIME(6) NOT NULL,
    summary VARCHAR(2048) NULL,
    outcome_status VARCHAR(32) NOT NULL,
    queen_status VARCHAR(32) NOT NULL,
    brood_status VARCHAR(32) NOT NULL,
    food_status VARCHAR(32) NOT NULL,
    temper_status VARCHAR(32) NOT NULL,
    strength_status VARCHAR(32) NOT NULL,
    follow_up_at DATETIME(6) NULL,
    source_type VARCHAR(32) NULL,
    source_group_hive_uuid VARCHAR(36) NULL,
    source_reminder_uuid VARCHAR(36) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_inspection_uuid (uuid)
);

CREATE TABLE work_group (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    group_type VARCHAR(40) NOT NULL,
    pasture_type VARCHAR(64) NULL,
    location_name VARCHAR(128) NULL,
    finished TINYINT(1) NOT NULL DEFAULT 0,
    active_type_key VARCHAR(40)
        AS (IF(date_deleted IS NULL, group_type, NULL)) STORED,
    PRIMARY KEY (id),
    UNIQUE KEY UK_work_group_uuid (uuid),
    UNIQUE KEY uk_work_group_user_active_type (user_id, active_type_key)
);

CREATE TABLE work_group_hive (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    group_uuid VARCHAR(36) NOT NULL,
    hive_uuid VARCHAR(36) NOT NULL,
    amount DOUBLE NULL,
    note VARCHAR(2000) NULL,
    check_date DATETIME(6) NULL,
    reminder_at DATETIME(6) NULL,
    pasture_type VARCHAR(80) NULL,
    location_name VARCHAR(200) NULL,
    done TINYINT(1) NOT NULL DEFAULT 0,
    membership_status VARCHAR(20) NOT NULL,
    active_from DATETIME(6) NULL,
    active_to DATETIME(6) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_work_group_hive_uuid (uuid)
);

CREATE TABLE reminder (
    id BIGINT NOT NULL AUTO_INCREMENT,
    date_created DATETIME(6) NULL,
    date_modified DATETIME(6) NULL,
    uuid VARCHAR(36) NOT NULL,
    user_id BIGINT NOT NULL,
    date_synched DATETIME(6) NULL,
    date_deleted DATETIME(6) NULL,
    hive_uuid VARCHAR(36) NULL,
    group_hive_uuid VARCHAR(36) NULL,
    inspection_uuid VARCHAR(36) NULL,
    due_at DATETIME(6) NOT NULL,
    title VARCHAR(256) NOT NULL,
    completed TINYINT(1) NOT NULL DEFAULT 0,
    notification_id VARCHAR(64) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY UK_reminder_uuid (uuid)
);
