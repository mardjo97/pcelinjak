#!/usr/bin/env bash
set -euo pipefail

# Manual fallback for Liquibase migration:
#   db/changelog/changes/20260809-work-group-dedupe-and-unique.xml
#
# Prefer deploying the backend — Quarkus Liquibase runs at startup:
#   1) dedupe work_group
#   2) add active_type_key
#   3) add UNIQUE (user_id, active_type_key)
#
# Use this script only for emergency / offline MySQL fix:
#   bash deploy/scripts/dedupe-work-groups.sh
#
# Optional env:
#   MYSQL_CONTAINER=mysql
#   MYSQL_DATABASE=pcelinjak
#   MYSQL_USER=root
#   MYSQL_PASSWORD=...

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_FILE="$SCRIPT_DIR/dedupe-work-groups.sql"

MYSQL_CONTAINER="${MYSQL_CONTAINER:-mysql}"
MYSQL_DATABASE="${MYSQL_DATABASE:-pcelinjak}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"

if [[ ! -f "$SQL_FILE" ]]; then
  echo "Missing SQL file: $SQL_FILE" >&2
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -qx "$MYSQL_CONTAINER"; then
  CANDIDATE=$(docker ps --format '{{.Names}}' | grep -E "_${MYSQL_CONTAINER}$|-${MYSQL_CONTAINER}$|^${MYSQL_CONTAINER}$" | head -n1 || true)
  if [[ -n "$CANDIDATE" ]]; then
    MYSQL_CONTAINER="$CANDIDATE"
  else
    echo "MySQL container not found (looked for '$MYSQL_CONTAINER'). Set MYSQL_CONTAINER." >&2
    exit 1
  fi
fi

echo "Running dedupe+unique (manual) against container=$MYSQL_CONTAINER db=$MYSQL_DATABASE ..."
if [[ -n "${MYSQL_PASSWORD}" ]]; then
  docker exec -i "$MYSQL_CONTAINER" \
    mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < "$SQL_FILE"
else
  docker exec -i "$MYSQL_CONTAINER" \
    mysql -u "$MYSQL_USER" "$MYSQL_DATABASE" < "$SQL_FILE"
fi
echo "Done. If you also deploy backend, Liquibase changeSets should MARK_RAN via preConditions or already match."
