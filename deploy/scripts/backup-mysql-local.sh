#!/usr/bin/env bash
set -euo pipefail

# Local emergency backup (temporary measure).
# Intended to run every 5 minutes via cron.
#
# Usage:
#   bash deploy/scripts/backup-mysql-local.sh
#
# Optional env vars:
#   BACKUP_DIR=/opt/Pcelinjak/.backups/local
#   KEEP_MINUTES=2880
#   SAVE_ONLY_ON_CHANGE=0   # 1 = do not keep new file if content matches previous dump
#   MYSQL_CONTAINER=mysql
#   MYSQL_DATABASE=Pcelinjak
#   MYSQL_USER=root
#   MYSQL_PASSWORD=<root password>
#   COMPOSE_PROJECT_NAME=Pcelinjak
#   COMPOSE_FILES="docker-compose.yml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/.backups/local}"
KEEP_MINUTES="${KEEP_MINUTES:-2880}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-mysql}"
MYSQL_DATABASE="${MYSQL_DATABASE:-Pcelinjak}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-root}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-Pcelinjak}"
COMPOSE_FILES="${COMPOSE_FILES:-docker-compose.yml}"
SAVE_ONLY_ON_CHANGE="${SAVE_ONLY_ON_CHANGE:-0}"

# Hash za poređenje dva dumpa: ukloni linije koje mysqldump menja pri svakom pokretanju.
logical_dump_sha256() {
  gunzip -c "$1" | sed '/^-- Dump completed on/d' | LC_ALL=C sha256sum | awk '{print $1}'
}

mkdir -p "$BACKUP_DIR"

compose_args=()
if [[ -n "$COMPOSE_PROJECT_NAME" ]]; then
  compose_args+=(-p "$COMPOSE_PROJECT_NAME")
fi
if [[ -n "$COMPOSE_FILES" ]]; then
  read -r -a compose_files_array <<< "$COMPOSE_FILES"
  for compose_file in "${compose_files_array[@]}"; do
    [[ -z "$compose_file" ]] && continue
    compose_args+=(-f "$compose_file")
  done
fi

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
archive_name="Pcelinjak_local_${timestamp}.sql.gz"
local_archive="$BACKUP_DIR/$archive_name"

cd "$PROJECT_ROOT"

docker compose "${compose_args[@]}" exec -T \
  -e MYSQL_PWD="$MYSQL_PASSWORD" \
  "$MYSQL_CONTAINER" \
  mysqldump \
  -u"$MYSQL_USER" \
  --single-transaction \
  --quick \
  --routines \
  --triggers \
  --events \
  --skip-dump-date \
  "$MYSQL_DATABASE" | gzip -9n > "$local_archive"

if [[ ! -s "$local_archive" ]]; then
  echo "ERROR: Local backup archive is empty: $local_archive" >&2
  exit 1
fi

if [[ "$SAVE_ONLY_ON_CHANGE" == "1" ]]; then
  previous_archive=""
  shopt -s nullglob
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ "$(basename "$f")" == "$archive_name" ]] && continue
    previous_archive="$f"
    break
  done < <(ls -1t "$BACKUP_DIR"/Pcelinjak_local_*.sql.gz 2>/dev/null)
  shopt -u nullglob
  if [[ -n "$previous_archive" && -f "$previous_archive" ]]; then
    new_hash="$(logical_dump_sha256 "$local_archive")"
    prev_hash="$(logical_dump_sha256 "$previous_archive")"
    if [[ "$new_hash" == "$prev_hash" ]]; then
      rm -f "$local_archive"
      echo "SKIP: no changes since previous backup ($previous_archive)"
      exit 0
    fi
  fi
fi

# Delete old local files (temporary ring buffer).
find "$BACKUP_DIR" -type f -name 'Pcelinjak_local_*.sql.gz' -mmin +"$KEEP_MINUTES" -delete || true

echo "OK: $local_archive"
