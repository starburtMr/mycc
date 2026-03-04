#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"
STATUS_FILE="$ROOT_DIR/0-System/status.md"

if [[ -z "$TASK_FILE" ]]; then
  echo "用法: bash scripts/guardrails/session_end.sh tasks/active/<task>.md" >&2
  exit 1
fi

TARGET="$ROOT_DIR/$TASK_FILE"
if [[ ! -f "$TARGET" ]]; then
  echo "任务文件不存在: $TARGET" >&2
  exit 1
fi

required_fields=(
  "progress"
  "next_step"
  "blocker"
  "verification"
  "risk"
  "decision_needed"
)

echo "[session_end] 校验交接字段"
for key in "${required_fields[@]}"; do
  if ! rg -n "^- ${key}:[[:space:]]*\\S+" "$TARGET" >/dev/null; then
    echo "缺少或为空字段: - ${key}:" >&2
    exit 1
  fi
  echo "- OK: - ${key}:"
done

if [[ ! -f "$STATUS_FILE" ]]; then
  echo "缺少状态文件: $STATUS_FILE" >&2
  exit 1
fi

if ! rg -n "^- summary:[[:space:]]*\\S+" "$STATUS_FILE" >/dev/null; then
  echo "0-System/status.md 缺少或为空 '- summary:' 字段" >&2
  exit 1
fi

if ! rg -n "^- next_focus:[[:space:]]*\\S+" "$STATUS_FILE" >/dev/null; then
  echo "0-System/status.md 缺少或为空 '- next_focus:' 字段" >&2
  exit 1
fi

echo "[session_end] 检查通过"
