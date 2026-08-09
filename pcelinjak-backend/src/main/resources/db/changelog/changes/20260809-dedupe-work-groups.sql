-- Dedupe active work_group rows: one canonical group per (user_id, group_type).
-- Memberships move to the group with most hives (then oldest). Duplicates are soft-deleted.

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
