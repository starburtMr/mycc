#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"

echo "[session_start] 必读文件检查"

required=(
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/0-System/about-me/SOUL.md"
  "$ROOT_DIR/0-System/about-me/persona.md"
  "$ROOT_DIR/0-System/about-me/user-profile.md"
  "$ROOT_DIR/tasks/index.md"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "缺少必读文件: $f" >&2
    exit 1
  fi
  echo "- OK: $f"
done

if [[ -f "$ROOT_DIR/AGENTS.md" ]]; then
  echo "- OK: $ROOT_DIR/AGENTS.md"
fi
if [[ -f "$ROOT_DIR/CLAUDE.md" ]]; then
  echo "- OK: $ROOT_DIR/CLAUDE.md"
fi

if [[ -n "$TASK_FILE" ]]; then
  if [[ ! -f "$ROOT_DIR/$TASK_FILE" ]]; then
    echo "任务文件不存在: $ROOT_DIR/$TASK_FILE" >&2
    exit 1
  fi
  echo "- OK: $ROOT_DIR/$TASK_FILE"
else
  echo "提示: 未指定任务文件。建议用法: bash scripts/guardrails/session_start.sh tasks/active/<task>.md"
fi

echo "[session_start] 检查通过"
