#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
BOOTSTRAP_SQL="$ROOT_DIR/memory/sql/bootstrap.sql"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 未安装，请先安装 sqlite3。" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/memory"

sqlite3 "$DB_PATH" < "$BOOTSTRAP_SQL"

echo "初始化完成: $DB_PATH"
sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
