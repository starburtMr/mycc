#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="${1:-help}"

usage() {
  cat <<'EOF'
用法:
  bash scripts/system/run.sh dev <task_file>
  bash scripts/system/run.sh ci
  bash scripts/system/run.sh monthly [YYYY-MM]
  bash scripts/system/run.sh intake <repo_dir> <source_url>
  bash scripts/system/run.sh help

模式说明:
  dev     会话开发模式（start -> closed_loop）
  ci      本地 CI 模式（guardrails + benchmark）
  monthly 月度治理（kpi + skill_review + auto_downgrade --dry-run）
  intake  第三方 skill 隔离导入
EOF
}

ensure_file() {
  local p="$1"
  if [[ ! -f "$p" ]]; then
    echo "文件不存在: $p" >&2
    exit 2
  fi
}

case "$MODE" in
  dev)
    TASK_FILE="${2:-}"
    if [[ -z "$TASK_FILE" ]]; then
      echo "缺少 task_file。示例: bash scripts/system/run.sh dev tasks/active/<task>.md" >&2
      exit 2
    fi
    if [[ ! "$TASK_FILE" =~ ^tasks/active/[^/]+\.md$ ]]; then
      echo "task_file 路径非法，仅允许 tasks/active/*.md: $TASK_FILE" >&2
      exit 2
    fi
    ensure_file "$ROOT_DIR/$TASK_FILE"
    bash "$ROOT_DIR/scripts/guardrails/session_start.sh" "$TASK_FILE"
    bash "$ROOT_DIR/scripts/loop/run_closed_loop.sh" "$TASK_FILE"
    ;;
  ci)
    bash "$ROOT_DIR/scripts/guardrails/check_capability_contracts.sh"
    bash "$ROOT_DIR/scripts/guardrails/check_workspace.sh"
    bash "$ROOT_DIR/scripts/benchmark/run_regression.sh"
    bash "$ROOT_DIR/memory/scripts/run_memory_checks.sh"
    ;;
  monthly)
    MONTH="${2:-$(date +%Y-%m)}"
    bash "$ROOT_DIR/scripts/loop/monthly_kpi.sh" "$MONTH"
    bash "$ROOT_DIR/scripts/skills/aggregate-skill-usage.sh"
    bash "$ROOT_DIR/scripts/skills/monthly_skill_review.sh" "$MONTH" "$ROOT_DIR/skills-core/monthly-skill-review-$MONTH.md" "$ROOT_DIR/skills-core/skill-usage.json"
    bash "$ROOT_DIR/scripts/skills/auto-downgrade.sh" --dry-run --out "$ROOT_DIR/skills-core/auto-downgrade-$MONTH.json"
    ;;
  intake)
    REPO_DIR="${2:-}"
    SOURCE_URL="${3:-}"
    if [[ -z "$REPO_DIR" || -z "$SOURCE_URL" ]]; then
      echo "缺少参数。示例: bash scripts/system/run.sh intake /tmp/ai-team-skills https://github.com/ThendCN/ai-team-skills" >&2
      exit 2
    fi
    bash "$ROOT_DIR/scripts/skills/import-repo-skills.sh" "$REPO_DIR" "$SOURCE_URL"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "未知模式: $MODE" >&2
    usage
    exit 2
    ;;
esac
