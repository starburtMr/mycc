#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
CHECKS_SQL="$ROOT_DIR/memory/sql/checks.sql"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 未安装，请先安装 sqlite3。" >&2
  exit 1
fi

if [[ ! -f "$DB_PATH" ]]; then
  echo "未找到数据库: $DB_PATH，请先运行 init_memory_db.sh" >&2
  exit 1
fi

echo "运行巡检: $DB_PATH"
sqlite3 -header -column "$DB_PATH" < "$CHECKS_SQL"
