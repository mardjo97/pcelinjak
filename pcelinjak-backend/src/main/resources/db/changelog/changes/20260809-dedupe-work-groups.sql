-- Dedupe active work_group rows: one canonical group per (user_id, group_type).
-- MySQL cannot join the same TEMPORARY table twice in one statement, so we
-- materialize winners/losers into separate temp tables.

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
