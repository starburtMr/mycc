#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"

echo "[self_check] 1/3 工作区巡检"
bash "$ROOT_DIR/scripts/guardrails/check_workspace.sh"

echo "[self_check] 2/3 SQLite 巡检"
bash "$ROOT_DIR/memory/scripts/run_memory_checks.sh"

if [[ -n "$TASK_FILE" ]]; then
  echo "[self_check] 3/3 会话闸门巡检 ($TASK_FILE)"
  bash "$ROOT_DIR/scripts/guardrails/session_start.sh" "$TASK_FILE"
  bash "$ROOT_DIR/scripts/guardrails/session_end.sh" "$TASK_FILE"
else
  echo "[self_check] 3/3 会话闸门巡检 (跳过，未传任务文件)"
fi

echo "[self_check] 全部通过"
