#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
CHECKS_SQL="$ROOT_DIR/memory/sql/checks.sql"
CHECKS_V2_SQL="$ROOT_DIR/memory/sql/checks_v2_memory_layers.sql"

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

has_fact="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='fact_memory';")"
has_working="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='working_memory';")"
if [[ "$has_fact" == "1" && "$has_working" == "1" && -f "$CHECKS_V2_SQL" ]]; then
  sqlite3 -header -column "$DB_PATH" < "$CHECKS_V2_SQL"
fi
