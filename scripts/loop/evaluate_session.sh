#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SESSION_DIR="${1:-}"
TASK_FILE="${2:-}"
TEST_CMD="${TEST_CMD:-}"

if [[ -z "$SESSION_DIR" || -z "$TASK_FILE" ]]; then
  echo "用法: bash scripts/loop/evaluate_session.sh <session_dir> <task_file>"
  exit 2
fi

mkdir -p "$SESSION_DIR/logs"

workspace_pass=true
if ! bash "$ROOT_DIR/scripts/guardrails/check_workspace.sh" >"$SESSION_DIR/logs/workspace_check.log" 2>&1; then
  workspace_pass=false
fi

tests_required=false
tests_pass=true
tests_status="skipped"
if [[ -n "$TEST_CMD" ]]; then
  tests_required=true
  tests_status="run"
  if ! bash -lc "$TEST_CMD" >"$SESSION_DIR/logs/tests.log" 2>&1; then
    tests_pass=false
    tests_status="failed"
  else
    tests_status="passed"
  fi
fi

python3 - "$SESSION_DIR/eval.json" "$workspace_pass" "$tests_required" "$tests_pass" "$tests_status" "$TASK_FILE" <<'PY'
import json
import sys
from datetime import datetime, UTC

out, workspace_pass, tests_required, tests_pass, tests_status, task_file = sys.argv[1:]
workspace_pass = workspace_pass == "true"
tests_required = tests_required == "true"
tests_pass = tests_pass == "true"

hard_pass = workspace_pass and (tests_pass if tests_required else True)
style_score = 0.7 if hard_pass else 0.4

data = {
    "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "task_file": task_file,
    "pass": hard_pass,
    "hard_checks": {
        "workspace_guardrails": workspace_pass,
        "tests_required": tests_required,
        "tests_status": tests_status,
        "tests_pass": tests_pass,
    },
    "scores": {
        "lint_score": 1.0 if workspace_pass else 0.0,
        "style_score": style_score,
    },
    "notes": [
        "hard checks 未通过时禁止规则晋级" if not hard_pass else "可进入反思与规则提炼阶段"
    ],
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

echo "评估完成: $SESSION_DIR/eval.json"
