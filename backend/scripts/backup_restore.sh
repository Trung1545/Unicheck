#!/usr/bin/env bash
# ==============================================================================
# UniCheck - Database Backup and Restore Utility Script (Linux/Docker)
# Target: PostgreSQL 15
# ==============================================================================
set -euo pipefail

ACTION="${1:-}"
DATABASE="${2:-unicheck_db}"
HOSTNAME="${DB_HOST:-localhost}"
PORT="${DB_PORT:-5432}"
USERNAME="${DB_USER:-unicheck_user}"
PASSWORD="${DB_PASSWORD:-unicheck_secret_password}"
BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/backups"

mkdir -p "$BACKUP_DIR"
export PGPASSWORD="$PASSWORD"

if [[ "$ACTION" == "backup" ]]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="${3:-$BACKUP_DIR/unicheck_backup_${DATABASE}_${TIMESTAMP}.sql}"
    echo "[UniCheck Backup] Starting backup for '$DATABASE'..."
    pg_dump -h "$HOSTNAME" -p "$PORT" -U "$USERNAME" -d "$DATABASE" --clean --if-exists --no-owner --no-privileges -f "$OUTPUT_FILE"
    echo "[UniCheck Backup] SUCCESS! Saved to $OUTPUT_FILE ($(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE") bytes)."
elif [[ "$ACTION" == "restore" ]]; then
    INPUT_FILE="${3:-}"
    if [[ -z "$INPUT_FILE" ]]; then
        INPUT_FILE=$(ls -t "$BACKUP_DIR"/*.sql 2>/dev/null | head -n 1 || true)
    fi
    if [[ -z "$INPUT_FILE" || ! -f "$INPUT_FILE" ]]; then
        echo "[UniCheck Restore] ERROR: Backup file not found!" >&2
        exit 1
    fi
    echo "[UniCheck Restore] Restoring '$DATABASE' from '$INPUT_FILE'..."
    psql -h "$HOSTNAME" -p "$PORT" -U "$USERNAME" -d "$DATABASE" -q -f "$INPUT_FILE"
    echo "[UniCheck Restore] SUCCESS! Database '$DATABASE' restored."
else
    echo "Usage: $0 [backup|restore] [database_name] [optional_filepath]"
    exit 1
fi
