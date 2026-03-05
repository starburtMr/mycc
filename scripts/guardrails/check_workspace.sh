#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_PATH="$ROOT_DIR/memory/memory.db"
CHECKS_SQL="$ROOT_DIR/memory/sql/checks.sql"
source "$ROOT_DIR/scripts/guardrails/lib.sh"

echo "[guardrails] 开始巡检"

# 1) 活跃任务必填字段巡检（非空）
required_task_fields=(
  "progress"
  "next_step"
  "blocker"
  "verification"
  "risk"
  "decision_needed"
  "route_model"
  "route_reason"
)

task_fail=0
declare -A seen_ids
shopt -s nullglob
for f in "$ROOT_DIR"/tasks/active/*.md; do
  base="$(basename "$f")"
  [[ "$base" == "TASK_TEMPLATE.md" || "$base" == "BLOCKED_TEMPLATE.md" || "$base" == "REVIEW_TEMPLATE.md" ]] && continue
  for key in "${required_task_fields[@]}"; do
    if ! rg -n "^- ${key}:[[:space:]]*\\S+" "$f" >/dev/null; then
      echo "[任务缺失或为空字段] $f -> - ${key}:"
      task_fail=1
    fi
  done

  id_val="$(read_field "$f" "id")"
  if [[ -z "$id_val" ]]; then
    echo "[id 缺失] $f"
    task_fail=1
  elif [[ ! "$id_val" =~ ^TASK-[0-9]{8}-[0-9A-Za-z._-]+$ ]]; then
    echo "[id 格式非法] $f -> $id_val"
    task_fail=1
  else
    if [[ -n "${seen_ids[$id_val]:-}" ]]; then
      echo "[id 重复] $f 与 ${seen_ids[$id_val]} -> $id_val"
      task_fail=1
    else
      seen_ids[$id_val]="$f"
    fi
  fi

  status_val="$(read_field "$f" "status" | tr '[:upper:]' '[:lower:]')"
  if [[ ! "$status_val" =~ ^(todo|doing|review|blocked)$ ]]; then
    echo "[status 非法] $f -> $status_val"
    task_fail=1
  fi

  owner_val="$(read_field "$f" "owner")"
  if [[ ! "$owner_val" =~ ^(Claude|Codex|User)$ ]]; then
    echo "[owner 非法] $f -> $owner_val"
    task_fail=1
  fi

  route_model_val="$(read_field "$f" "route_model")"
  route_reason_val="$(read_field "$f" "route_reason")"
  if is_placeholder_value "$route_model_val"; then
    echo "[route_model 为占位值] $f -> $route_model_val"
    task_fail=1
  fi
  if is_placeholder_value "$route_reason_val"; then
    echo "[route_reason 为占位值] $f -> $route_reason_val"
    task_fail=1
  fi

  # 技术执行类任务附加校验
  type_val="$(read_field "$f" "type")"
  if is_technical_task_type "$type_val"; then
    for tech_key in attempt_count attempt_summary stop_reason; do
      if ! rg -n "^- ${tech_key}:[[:space:]]*\\S+" "$f" >/dev/null; then
        echo "[技术任务缺失或为空字段] $f -> - ${tech_key}:"
        task_fail=1
      fi
    done
    attempt_count_val="$(read_field "$f" "attempt_count")"
    if ! [[ "$attempt_count_val" =~ ^[0-9]+$ ]]; then
      echo "[attempt_count 非法] $f -> $attempt_count_val"
      task_fail=1
    fi
  fi

  # 任务绑定项目时，校验项目上下文文件
  project_val="$(read_field "$f" "project")"
  if [[ -z "$project_val" ]]; then
    echo "[任务缺少 project 字段] $f"
    task_fail=1
  elif is_placeholder_value "$project_val"; then
    echo "[project 为占位值] $f -> $project_val"
    task_fail=1
  elif ! is_valid_project_name "$project_val"; then
    echo "[project 字段非法] $f -> $project_val"
    task_fail=1
  else
    if [[ ! -f "$ROOT_DIR/2-Projects/$project_val/context/PROJECT_CONTEXT.md" ]]; then
      echo "[缺少项目上下文] $ROOT_DIR/2-Projects/$project_val/context/PROJECT_CONTEXT.md"
      task_fail=1
    fi
    if [[ ! -f "$ROOT_DIR/2-Projects/$project_val/context/TOOLING_PROFILE.md" ]]; then
      echo "[缺少项目工具白名单] $ROOT_DIR/2-Projects/$project_val/context/TOOLING_PROFILE.md"
      task_fail=1
    fi
  fi
done

# 追加检查：done/archived 中不应与 active 出现重复 id
for f in "$ROOT_DIR"/tasks/done/*.md "$ROOT_DIR"/tasks/archived/*.md; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  [[ "$base" == "DONE_TEMPLATE.md" || "$base" == "ARCHIVED_TEMPLATE.md" ]] && continue
  id_val="$(read_field "$f" "id")"
  [[ -z "$id_val" ]] && continue
  if [[ -n "${seen_ids[$id_val]:-}" ]]; then
    echo "[id 与 active 重复] $f 与 ${seen_ids[$id_val]} -> $id_val"
    task_fail=1
  fi
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

# 2.5) Prompt/Reflection 软检查（仅告警，不阻断）
if [[ ! -f "$ROOT_DIR/4-Assets/prompts/00-system.md" ]]; then
  echo "[告警] 缺少 prompt 模板: $ROOT_DIR/4-Assets/prompts/00-system.md"
fi
if [[ ! -f "$ROOT_DIR/3-Thinking/reflection/session-wrap.md" ]]; then
  echo "[告警] 缺少反思模板: $ROOT_DIR/3-Thinking/reflection/session-wrap.md"
fi
if [[ ! -f "$ROOT_DIR/3-Thinking/reflection/daily-reflection.md" ]]; then
  echo "[告警] 缺少反思模板: $ROOT_DIR/3-Thinking/reflection/daily-reflection.md"
fi

# 2.6) Skill Router 一致性软检查（仅告警，不阻断）
if [[ -x "$ROOT_DIR/scripts/guardrails/check_skills_consistency.sh" ]]; then
  if ! bash "$ROOT_DIR/scripts/guardrails/check_skills_consistency.sh" >/tmp/mycc_skills_check.log 2>&1; then
    echo "[告警] Skill Router 一致性检查失败"
    sed -n '1,20p' /tmp/mycc_skills_check.log
  fi
else
  echo "[告警] 缺少 skills 一致性脚本: $ROOT_DIR/scripts/guardrails/check_skills_consistency.sh"
fi

# 2.7) Skill post-install hook 软检查（仅告警，不阻断）
if [[ ! -x "$ROOT_DIR/scripts/skills/post-install.sh" ]]; then
  echo "[告警] 缺少或不可执行: $ROOT_DIR/scripts/skills/post-install.sh"
fi
if [[ ! -x "$ROOT_DIR/scripts/skills/skill-import-from-env.sh" ]]; then
  echo "[告警] 缺少或不可执行: $ROOT_DIR/scripts/skills/skill-import-from-env.sh"
fi

# 2.8) 自动进化闭环软检查（仅告警，不阻断）
if [[ ! -x "$ROOT_DIR/scripts/loop/run_closed_loop.sh" ]]; then
  echo "[告警] 缺少或不可执行: $ROOT_DIR/scripts/loop/run_closed_loop.sh"
fi
if [[ ! -x "$ROOT_DIR/scripts/loop/evaluate_session.sh" ]]; then
  echo "[告警] 缺少或不可执行: $ROOT_DIR/scripts/loop/evaluate_session.sh"
fi
if [[ ! -f "$ROOT_DIR/0-System/policy/staging-rules.md" ]]; then
  echo "[告警] 缺少规则暂存区: $ROOT_DIR/0-System/policy/staging-rules.md"
fi
if [[ ! -f "$ROOT_DIR/0-System/policy/stable-rules.md" ]]; then
  echo "[告警] 缺少稳定规则文件: $ROOT_DIR/0-System/policy/stable-rules.md"
fi

# 3) SQLite 登记巡检
db_fail=0
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "[警告] 未安装 sqlite3，无法执行 SQLite 巡检"
  db_fail=1
fi
if [[ -f "$DB_PATH" ]]; then
  if [[ -f "$CHECKS_SQL" && $db_fail -eq 0 ]]; then
    out="$(sqlite3 -noheader "$DB_PATH" < "$CHECKS_SQL" || true)"
    if [[ -n "$out" ]]; then
      echo "[SQLite 巡检异常]"
      echo "$out"
      db_fail=1
    fi
  elif [[ $db_fail -eq 0 ]]; then
    echo "[警告] 缺少 checks.sql: $CHECKS_SQL"
    db_fail=1
  fi
elif [[ $db_fail -eq 0 ]]; then
  echo "[警告] 缺少数据库: $DB_PATH"
  db_fail=1
fi

if [[ $task_fail -eq 0 && $tooling_fail -eq 0 && $db_fail -eq 0 ]]; then
  echo "[guardrails] 巡检通过"
  exit 0
fi

echo "[guardrails] 巡检失败"
exit 1
