#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
CHECKS_SQL="$ROOT_DIR/memory/sql/checks.sql"

echo "[guardrails] 开始巡检"

# 1) 活跃任务必填字段巡检
required_task_fields=(
  "- progress:"
  "- next_step:"
  "- blocker:"
  "- verification:"
  "- risk:"
  "- decision_needed:"
)

task_fail=0
shopt -s nullglob
for f in "$ROOT_DIR"/tasks/active/*.md; do
  base="$(basename "$f")"
  [[ "$base" == "TASK_TEMPLATE.md" || "$base" == "BLOCKED_TEMPLATE.md" || "$base" == "REVIEW_TEMPLATE.md" ]] && continue
  for p in "${required_task_fields[@]}"; do
    if ! rg -n "^${p//\//\\/}" "$f" >/dev/null; then
      echo "[任务缺失字段] $f -> ${p}"
      task_fail=1
    fi
  done
done

# 2) 项目 TOOLING_PROFILE 巡检
tooling_fail=0
for d in "$ROOT_DIR"/2-Projects/*; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  [[ "$name" == ".git" || "$name" == "_template-project" ]] && continue
  profile="$d/context/TOOLING_PROFILE.md"
  if [[ ! -f "$profile" ]]; then
    echo "[缺少工具白名单] $profile"
    tooling_fail=1
  fi
done

# 3) SQLite 登记巡检
db_fail=0
if [[ -f "$DB_PATH" ]]; then
  if [[ -f "$CHECKS_SQL" ]]; then
    out="$(sqlite3 -noheader "$DB_PATH" < "$CHECKS_SQL" || true)"
    if [[ -n "$out" ]]; then
      echo "[SQLite 巡检异常]"
      echo "$out"
      db_fail=1
    fi
  else
    echo "[警告] 缺少 checks.sql: $CHECKS_SQL"
    db_fail=1
  fi
else
  echo "[警告] 缺少数据库: $DB_PATH"
  db_fail=1
fi

if [[ $task_fail -eq 0 && $tooling_fail -eq 0 && $db_fail -eq 0 ]]; then
  echo "[guardrails] 巡检通过"
  exit 0
fi

echo "[guardrails] 巡检失败"
exit 1
