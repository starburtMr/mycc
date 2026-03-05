#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"
source "$ROOT_DIR/scripts/guardrails/lib.sh"

echo "[session_start] 必读文件检查"

if [[ -z "$TASK_FILE" ]]; then
  echo "缺少任务文件参数。用法: bash scripts/guardrails/session_start.sh tasks/active/<task>.md" >&2
  exit 1
fi

if [[ ! "$TASK_FILE" =~ ^tasks/active/[^/]+\.md$ ]]; then
  echo "任务文件路径非法，仅允许 tasks/active/*.md: $TASK_FILE" >&2
  exit 1
fi

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

if [[ ! -f "$ROOT_DIR/$TASK_FILE" ]]; then
  echo "任务文件不存在: $ROOT_DIR/$TASK_FILE" >&2
  exit 1
fi

echo "- OK: $ROOT_DIR/$TASK_FILE"

base="$(basename "$TASK_FILE")"
if [[ "$base" == "TASK_TEMPLATE.md" || "$base" == "BLOCKED_TEMPLATE.md" || "$base" == "REVIEW_TEMPLATE.md" ]]; then
  echo "任务文件不能使用模板文件: $TASK_FILE" >&2
  exit 1
fi

# 从任务文件读取项目名，校验项目上下文是否存在
project="$(read_field "$ROOT_DIR/$TASK_FILE" "project")"
if [[ -z "$project" ]]; then
  echo "任务缺少 project 字段，无法建立项目上下文绑定: $TASK_FILE" >&2
  exit 1
fi

if ! is_valid_project_name "$project"; then
  echo "project 字段非法，仅允许字母/数字/._-: $project" >&2
  exit 1
fi

project_context="$ROOT_DIR/2-Projects/$project/context/PROJECT_CONTEXT.md"
project_tooling="$ROOT_DIR/2-Projects/$project/context/TOOLING_PROFILE.md"
if [[ ! -f "$project_context" ]]; then
  echo "缺少项目上下文文件: $project_context" >&2
  exit 1
fi
if [[ ! -f "$project_tooling" ]]; then
  echo "缺少项目工具白名单文件: $project_tooling" >&2
  exit 1
fi
echo "- OK: $project_context"
echo "- OK: $project_tooling"

# EvoMap 经验预检（先查再做）
if [[ -f "$ROOT_DIR/scripts/evomap/lib.sh" && -f "$ROOT_DIR/scripts/evomap/preflight_search.sh" ]]; then
  source "$ROOT_DIR/scripts/evomap/lib.sh"
  echo "[session_start] EvoMap 经验预检"
  if ! bash "$ROOT_DIR/scripts/evomap/preflight_search.sh" "$TASK_FILE"; then
    if [[ "${EVOMAP_STRICT:-0}" == "1" ]]; then
      echo "EvoMap 预检失败，且处于严格模式，阻断会话开始。" >&2
      exit 1
    fi
    echo "警告: EvoMap 预检失败（非严格模式，继续执行）。"
  fi
fi

echo "[session_start] 检查通过"
