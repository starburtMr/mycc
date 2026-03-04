#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"
STATUS_FILE="$ROOT_DIR/0-System/status.md"
source "$ROOT_DIR/scripts/guardrails/lib.sh"

if [[ -z "$TASK_FILE" ]]; then
  echo "用法: bash scripts/guardrails/session_end.sh tasks/active/<task>.md" >&2
  exit 1
fi

if [[ ! "$TASK_FILE" =~ ^tasks/active/[^/]+\.md$ ]]; then
  echo "任务文件路径非法，仅允许 tasks/active/*.md: $TASK_FILE" >&2
  exit 1
fi

TARGET="$ROOT_DIR/$TASK_FILE"
if [[ ! -f "$TARGET" ]]; then
  echo "任务文件不存在: $TARGET" >&2
  exit 1
fi

project_val="$(read_field "$TARGET" "project")"
if [[ -z "$project_val" ]]; then
  echo "任务缺少 project 字段，无法完成会话收尾校验: $TASK_FILE" >&2
  exit 1
fi
if ! is_valid_project_name "$project_val"; then
  echo "project 字段非法，仅允许字母/数字/._-: $project_val" >&2
  exit 1
fi

project_context="$ROOT_DIR/2-Projects/$project_val/context/PROJECT_CONTEXT.md"
project_tooling="$ROOT_DIR/2-Projects/$project_val/context/TOOLING_PROFILE.md"
if [[ ! -f "$project_context" ]]; then
  echo "缺少项目上下文文件: $project_context" >&2
  exit 1
fi
if [[ ! -f "$project_tooling" ]]; then
  echo "缺少项目工具白名单文件: $project_tooling" >&2
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

type_val="$(read_field "$TARGET" "type")"
if is_technical_task_type "$type_val"; then
  for tech_key in attempt_count attempt_summary stop_reason; do
    if ! rg -n "^- ${tech_key}:[[:space:]]*\\S+" "$TARGET" >/dev/null; then
      echo "技术任务缺少或为空字段: - ${tech_key}:" >&2
      exit 1
    fi
    echo "- OK: - ${tech_key}:"
  done
fi

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
