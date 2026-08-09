-- Manual / emergency fallback for the Liquibase changeSets in:
--   pcelinjak-backend/src/main/resources/db/changelog/changes/20260809-work-group-dedupe-and-unique.xml
--
-- Prefer: deploy backend — Liquibase runs automatically (dedupe, then unique).
--
-- Usage if you must run by hand before unique exists:
--   bash deploy/scripts/dedupe-work-groups.sh
--
-- Order matches Liquibase: 1) dedupe  2) active_type_key  3) unique index

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS wg_ranked;
CREATE TEMPORARY TABLE wg_ranked AS
SELECT
  wg.id,
  wg.uuid,
  wg.user_id,
  wg.group_type,
  ROW_NUMBER() OVER (
    PARTITION BY wg.user_id, wg.group_type
    ORDER BY (
      SELECT COUNT(*)
      FROM work_group_hive wgh
      WHERE wgh.group_uuid = wg.uuid
        AND wgh.date_deleted IS NULL
    ) DESC,
    wg.date_created ASC,
    wg.id ASC
  ) AS rn
FROM work_group wg
WHERE wg.date_deleted IS NULL;

UPDATE work_group_hive wgh
INNER JOIN wg_ranked loser
  ON loser.uuid = wgh.group_uuid
 AND loser.rn > 1
INNER JOIN wg_ranked winner
  ON winner.user_id = loser.user_id
 AND winner.group_type = loser.group_type
 AND winner.rn = 1
SET
  wgh.group_uuid = winner.uuid,
  wgh.date_modified = UTC_TIMESTAMP(3);

UPDATE work_group wg
INNER JOIN wg_ranked r
  ON r.uuid = wg.uuid
 AND r.rn > 1
SET
  wg.date_deleted = UTC_TIMESTAMP(3),
  wg.date_modified = UTC_TIMESTAMP(3);

DROP TEMPORARY TABLE IF EXISTS wg_ranked;

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'work_group'
    AND COLUMN_NAME = 'active_type_key'
);

SET @sql := IF(
  @col_exists = 0,
  'ALTER TABLE work_group ADD COLUMN active_type_key VARCHAR(40) AS (IF(date_deleted IS NULL, group_type, NULL)) STORED',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'work_group'
    AND INDEX_NAME = 'uk_work_group_user_active_type'
);

SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE work_group ADD UNIQUE KEY uk_work_group_user_active_type (user_id, active_type_key)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

COMMIT;

SELECT
  user_id,
  group_type,
  COUNT(*) AS active_groups
FROM work_group
WHERE date_deleted IS NULL
GROUP BY user_id, group_type
ORDER BY user_id, group_type;
