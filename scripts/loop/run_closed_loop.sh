#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"
SESSION_ID="${2:-session-$(date +%Y%m%dT%H%M%S)}"
SESSION_DIR="$ROOT_DIR/3-Thinking/sessions/$SESSION_ID"
POLICY_STAGING="$ROOT_DIR/0-System/policy/staging-rules.md"
RUN_ID="run-$(date +%Y%m%dT%H%M%S)-$RANDOM"
TOOL_LOG="$ROOT_DIR/scripts/loop/log_tool_call.sh"

if [[ -z "$TASK_FILE" ]]; then
  echo "用法: bash scripts/loop/run_closed_loop.sh tasks/active/<task>.md [session_id]"
  exit 2
fi

if [[ ! "$TASK_FILE" =~ ^tasks/active/[^/]+\.md$ ]]; then
  echo "任务文件路径非法，仅允许 tasks/active/*.md: $TASK_FILE"
  exit 2
fi

if [[ ! -f "$ROOT_DIR/$TASK_FILE" ]]; then
  echo "任务文件不存在: $ROOT_DIR/$TASK_FILE"
  exit 2
fi

mkdir -p "$SESSION_DIR/logs"

python3 - "$SESSION_DIR/run_manifest.json" "$RUN_ID" "$SESSION_ID" "$TASK_FILE" <<'PY'
import json
import sys
from datetime import datetime, UTC

out, run_id, session_id, task_file = sys.argv[1:]
data = {
  "run_id": run_id,
  "session_id": session_id,
  "task_file": task_file,
  "started_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
  "status": "running",
}
with open(out, "w", encoding="utf-8") as f:
  json.dump(data, f, ensure_ascii=False, indent=2)
PY

# 1) PLAN 前置闸门
bash "$TOOL_LOG" "$SESSION_DIR" "guardrail" "session_start.sh" "start" "会话开始闸门"
bash "$ROOT_DIR/scripts/guardrails/session_start.sh" "$TASK_FILE" >"$SESSION_DIR/logs/session_start.log" 2>&1
bash "$TOOL_LOG" "$SESSION_DIR" "guardrail" "session_start.sh" "ok" "会话开始闸门通过"

# 2) 记录本轮输入
cat > "$SESSION_DIR/input.md" <<INPUT
# Session Input

- session_id: $SESSION_ID
- task_file: $TASK_FILE
- started_at: $(date -u +%FT%TZ)

## 任务快照

INPUT
cat "$ROOT_DIR/$TASK_FILE" >> "$SESSION_DIR/input.md"

# 3) 生成计划与执行占位文件
cat > "$SESSION_DIR/plan.md" <<'PLAN'
# PLAN

- 目标：
- 约束：
- 最小方案：
- 不做范围：
- 验证步骤：
PLAN

cat > "$SESSION_DIR/execute.md" <<'EXEC'
# EXECUTE

- 实际改动文件：
- 关键命令：
- 输出摘要：
EXEC

# 4) 结构化评估
bash "$TOOL_LOG" "$SESSION_DIR" "loop" "evaluate_session.sh" "start" ""
RUN_ID="$RUN_ID" bash "$ROOT_DIR/scripts/loop/evaluate_session.sh" "$SESSION_DIR" "$TASK_FILE"
bash "$TOOL_LOG" "$SESSION_DIR" "loop" "evaluate_session.sh" "ok" "输出 eval.json"

# 5) 反思与规则建议
python3 - "$SESSION_DIR/eval.json" "$SESSION_DIR/reflection.md" "$SESSION_ID" <<'PY'
import json
import sys
from datetime import datetime, UTC

in_file, out_file, session_id = sys.argv[1:]
with open(in_file, "r", encoding="utf-8") as f:
    data = json.load(f)

passed = bool(data.get("pass"))
notes = data.get("notes", [])
generated = datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
lines = [
    "# Reflection",
    "",
    "## Session Meta",
    "",
    f"- session_id: {session_id}",
    f"- generated_at: {generated}",
    f"- hard_pass: {'true' if passed else 'false'}",
    "",
    "## Failures",
    "",
]
if notes:
    for n in notes:
        lines += [
            "- trigger: 评估阶段",
            f"- failure_cause: {n}",
            "- evidence_file: eval.json",
            "",
        ]
else:
    lines += [
        "- trigger: none",
        "- failure_cause: none",
        "- evidence_file: eval.json",
        "",
    ]

lines += [
    "## Candidate Rules (Executable)",
    "",
    "- rule_statement: 如果任务进入方案评估阶段且存在多方案分歧，则必须给出 1 个推荐方案与回滚路径。",
    "- verify_plan: 检查交付内容是否同时包含 `推荐方案` 和 `回滚步骤`。",
    "- owner: Codex",
    f"- next_action: {'promote' if passed else 'revise'}",
    "",
    "- rule_statement: 非 verified skill 不得进入默认路由。",
    "- verify_plan: 运行 check_skills_consistency.sh，确保 default_enabled 仅对 verified 为 true。",
    "- owner: Codex",
    "- next_action: promote",
]

with open(out_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
PY

if [[ -f "$POLICY_STAGING" ]]; then
  PASS_FLAG="$(python3 - "$SESSION_DIR/eval.json" <<'PY'
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d=json.load(f)
print('pass' if d.get('pass') else 'fail')
PY
)"
  cat >> "$POLICY_STAGING" <<EOF_STAGING
- id: RULE-$(date +%Y%m%d)-$SESSION_ID
- source_session: $SESSION_ID
- proposal: 如果任务进入方案评估阶段且存在多方案分歧，则必须给出 1 个推荐方案与回滚路径。
- trigger: 任务进入方案评估阶段且存在多方案分歧
- verify: 检查交付是否包含推荐方案与回滚步骤
- result: $PASS_FLAG
- next_action: revise

EOF_STAGING
fi

python3 - "$SESSION_DIR/run_manifest.json" "$RUN_ID" <<'PY'
import json
import sys
from datetime import datetime, UTC

path, run_id = sys.argv[1:]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
data["run_id"] = run_id
data["finished_at"] = datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
data["status"] = "completed"
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

echo "闭环完成: $SESSION_DIR"
echo "run_id: $RUN_ID"
echo "下一步：执行结束前可手动运行 session_end 校验"
