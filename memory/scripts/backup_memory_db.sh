#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
BACKUP_DIR="$ROOT_DIR/memory/backup"
TS="$(date +%Y%m%d_%H%M%S)"
DAILY_BACKUP="$BACKUP_DIR/memory_${TS}.db"
WEEKLY_LINK="$BACKUP_DIR/weekly_latest.db"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 未安装，请先安装 sqlite3。" >&2
  exit 1
fi

if [[ ! -f "$DB_PATH" ]]; then
  echo "未找到数据库: $DB_PATH" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

sqlite3 "$DB_PATH" ".backup '$DAILY_BACKUP'"
ln -sfn "$(basename "$DAILY_BACKUP")" "$WEEKLY_LINK"

echo "备份完成: $DAILY_BACKUP"
echo "每周最新快照链接: $WEEKLY_LINK -> $(readlink "$WEEKLY_LINK")"
