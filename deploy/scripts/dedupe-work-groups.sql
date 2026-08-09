-- Manual / emergency fallback for Liquibase work-group dedupe + unique.
-- Prefer backend deploy (Liquibase). MySQL cannot join one TEMP table twice.

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS wg_ranked;
DROP TEMPORARY TABLE IF EXISTS wg_winners;
DROP TEMPORARY TABLE IF EXISTS wg_losers;

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

CREATE TEMPORARY TABLE wg_winners AS
SELECT * FROM wg_ranked WHERE rn = 1;

CREATE TEMPORARY TABLE wg_losers AS
SELECT * FROM wg_ranked WHERE rn > 1;

UPDATE work_group_hive wgh
INNER JOIN wg_losers loser
  ON loser.uuid = wgh.group_uuid
INNER JOIN wg_winners winner
  ON winner.user_id = loser.user_id
 AND winner.group_type = loser.group_type
SET
  wgh.group_uuid = winner.uuid,
  wgh.date_modified = UTC_TIMESTAMP(3);

UPDATE work_group wg
INNER JOIN wg_losers loser
  ON loser.uuid = wg.uuid
SET
  wg.date_deleted = UTC_TIMESTAMP(3),
  wg.date_modified = UTC_TIMESTAMP(3);

DROP TEMPORARY TABLE IF EXISTS wg_losers;
DROP TEMPORARY TABLE IF EXISTS wg_winners;
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
