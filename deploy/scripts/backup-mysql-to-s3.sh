#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"
}

fail() {
  log "ERROR: $*"
  if [[ -n "${BACKUP_NOTIFY_EMAIL:-}" ]] && command -v mail >/dev/null 2>&1; then
    printf 'Pcelinjak backup failed on %s\nReason: %s\n' "$(hostname)" "$*" | mail -s "Pcelinjak backup FAILED" "$BACKUP_NOTIFY_EMAIL" || true
  fi
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_ENV_FILE="${BACKUP_ENV_FILE:-$PROJECT_ROOT/.backup.env}"

[[ -f "$BACKUP_ENV_FILE" ]] || fail "Missing backup env file: $BACKUP_ENV_FILE"
# shellcheck source=/dev/null
source "$BACKUP_ENV_FILE"

required_vars=(
  S3_BUCKET
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    fail "Required variable is missing: $var_name"
  fi
done

# .backup.env koristi obicne dodele; aws se pokrece kao podproces i vidi samo exportovane promenljive
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-${S3_REGION:-us-east-1}}"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

MYSQL_CONTAINER="${MYSQL_CONTAINER:-mysql}"
MYSQL_DATABASE="${MYSQL_DATABASE:-Pcelinjak}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-root}"
S3_PREFIX="${S3_PREFIX:-Pcelinjak/mysql}"
LOG_S3_PREFIX="${LOG_S3_PREFIX:-Pcelinjak/logs}"
LOG_SOURCE_DIR="${LOG_SOURCE_DIR:-$PROJECT_ROOT/logs/backend}"
BACKUP_LOGS_ENABLED="${BACKUP_LOGS_ENABLED:-1}"
BACKUP_TMP_DIR="${BACKUP_TMP_DIR:-/tmp/Pcelinjak-backups}"
LOCAL_RETENTION_DAYS="${LOCAL_RETENTION_DAYS:-7}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-}"
COMPOSE_FILES="${COMPOSE_FILES:-}"

compose_args=()
if [[ -n "$COMPOSE_PROJECT_NAME" ]]; then
  compose_args+=(-p "$COMPOSE_PROJECT_NAME")
fi
if [[ -n "$COMPOSE_FILES" ]]; then
  # Space-separated list, e.g. "docker-compose.yml docker-compose.test.yml"
  read -r -a compose_files_array <<< "$COMPOSE_FILES"
  for compose_file in "${compose_files_array[@]}"; do
    [[ -z "$compose_file" ]] && continue
    compose_args+=(-f "$compose_file")
  done
fi

command -v docker >/dev/null 2>&1 || fail "docker is not installed"
docker compose "${compose_args[@]}" version >/dev/null 2>&1 || fail "docker compose is not available"
command -v aws >/dev/null 2>&1 || fail "aws cli is not installed"

mkdir -p "$BACKUP_TMP_DIR"

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
year="$(date -u +'%Y')"
month="$(date -u +'%m')"
archive_name="Pcelinjak_${timestamp}.sql.gz"
local_archive="$BACKUP_TMP_DIR/$archive_name"
s3_key="${S3_PREFIX}/${year}/${month}/${archive_name}"
s3_uri="s3://${S3_BUCKET}/${s3_key}"
logs_archive_name="Pcelinjak_logs_${timestamp}.tar.gz"
local_logs_archive="$BACKUP_TMP_DIR/$logs_archive_name"
logs_s3_key="${LOG_S3_PREFIX}/${year}/${month}/${logs_archive_name}"
logs_s3_uri="s3://${S3_BUCKET}/${logs_s3_key}"

cd "$PROJECT_ROOT"
log "Starting MySQL backup for database '$MYSQL_DATABASE'"

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
  "$MYSQL_DATABASE" | gzip -9 > "$local_archive"

if [[ ! -s "$local_archive" ]]; then
  fail "Backup archive is empty: $local_archive"
fi

aws_args=()
if [[ -n "${S3_ENDPOINT:-}" ]]; then
  aws_args+=(--endpoint-url "$S3_ENDPOINT")
fi

log "Uploading backup to $s3_uri"
aws "${aws_args[@]}" s3 cp "$local_archive" "$s3_uri" --only-show-errors || fail "Upload to S3 failed"

if [[ "$BACKUP_LOGS_ENABLED" == "1" ]]; then
  if [[ -d "$LOG_SOURCE_DIR" ]]; then
    log "Creating logs archive from $LOG_SOURCE_DIR"
    tar -czf "$local_logs_archive" -C "$LOG_SOURCE_DIR" .
    if [[ -s "$local_logs_archive" ]]; then
      log "Uploading logs backup to $logs_s3_uri"
      aws "${aws_args[@]}" s3 cp "$local_logs_archive" "$logs_s3_uri" --only-show-errors || fail "Upload logs backup to S3 failed"
    else
      log "Logs archive is empty, skipping upload."
      rm -f "$local_logs_archive" || true
    fi
  else
    log "Logs source directory not found: $LOG_SOURCE_DIR (skipping logs backup)"
  fi
fi

if [[ "${APPLY_RETENTION_FALLBACK:-0}" == "1" ]]; then
  log "Applying fallback retention (${RETENTION_DAYS:-90} days)"
  aws "${aws_args[@]}" s3api list-objects-v2 \
    --bucket "$S3_BUCKET" \
    --prefix "$S3_PREFIX/" \
    --query "Contents[?LastModified<='$(date -u -d "-${RETENTION_DAYS:-90} days" +%Y-%m-%dT%H:%M:%SZ)'].Key" \
    --output text | tr '\t' '\n' | while IFS= read -r old_key; do
      [[ -z "$old_key" || "$old_key" == "None" ]] && continue
      aws "${aws_args[@]}" s3 rm "s3://${S3_BUCKET}/${old_key}" --only-show-errors || true
    done
fi

find "$BACKUP_TMP_DIR" -type f -name '*.sql.gz' -mtime +"$LOCAL_RETENTION_DAYS" -delete || true
find "$BACKUP_TMP_DIR" -type f -name '*.tar.gz' -mtime +"$LOCAL_RETENTION_DAYS" -delete || true

size_bytes="$(wc -c < "$local_archive" | tr -d '[:space:]')"
logs_size_bytes="0"
if [[ -f "$local_logs_archive" ]]; then
  logs_size_bytes="$(wc -c < "$local_logs_archive" | tr -d '[:space:]')"
fi
log "Backup completed successfully. DbSize=${size_bytes}B, LogsSize=${logs_size_bytes}B, DbTarget=${s3_uri}, LogsTarget=${logs_s3_uri}"

if [[ -n "${BACKUP_NOTIFY_EMAIL:-}" ]] && command -v mail >/dev/null 2>&1; then
  printf 'Pcelinjak backup success on %s\nDB file: %s\nDB size: %s bytes\nLogs file: %s\nLogs size: %s bytes\n' "$(hostname)" "$s3_uri" "$size_bytes" "$logs_s3_uri" "$logs_size_bytes" | mail -s "Pcelinjak backup OK" "$BACKUP_NOTIFY_EMAIL" || true
fi
