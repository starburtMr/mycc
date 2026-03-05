#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
MIGRATION_SQL="$ROOT_DIR/memory/sql/migrations/20260305_memory_layers.sql"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "缺少 sqlite3，无法执行迁移" >&2
  exit 1
fi

if [[ ! -f "$DB_PATH" ]]; then
  echo "数据库不存在: $DB_PATH，请先 init_memory_db.sh" >&2
  exit 1
fi
if [[ ! -f "$MIGRATION_SQL" ]]; then
  echo "迁移 SQL 不存在: $MIGRATION_SQL" >&2
  exit 1
fi

sqlite3 "$DB_PATH" < "$MIGRATION_SQL"
bash "$ROOT_DIR/memory/scripts/run_memory_checks.sh"
echo "迁移完成：memory v2 分层记忆已生效"
