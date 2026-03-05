#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_FILE="${1:-}"
SESSION_ID="${2:-session-$(date +%Y%m%dT%H%M%S)}"
SESSION_DIR="$ROOT_DIR/3-Thinking/sessions/$SESSION_ID"
POLICY_STAGING="$ROOT_DIR/0-System/policy/staging-rules.md"

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

# 1) PLAN 前置闸门
bash "$ROOT_DIR/scripts/guardrails/session_start.sh" "$TASK_FILE" >"$SESSION_DIR/logs/session_start.log" 2>&1

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
bash "$ROOT_DIR/scripts/loop/evaluate_session.sh" "$SESSION_DIR" "$TASK_FILE"

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
lines = [
    "# Reflection",
    "",
    f"- session_id: {session_id}",
    f"- generated_at: {datetime.now(UTC).replace(microsecond=0).isoformat().replace('+00:00', 'Z')}",
    f"- hard_pass: {'true' if passed else 'false'}",
    "",
    "## 结论",
    "",
    "- 本轮通过硬评估，可提炼规则进入 staging。" if passed else "- 本轮未通过硬评估，先修复问题，禁止规则晋级。",
    "",
    "## 观察",
    "",
]
for n in notes:
    lines.append(f"- {n}")

lines += [
    "",
    "## 候选规则（可执行）",
    "",
    "- 如果任务存在多方案分歧，先输出 1 个推荐方案 + 回滚路径。",
    "- 任何规则晋级前，至少 3 次会话验证通过。",
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
- proposal: 如果任务存在多方案分歧，先输出 1 个推荐方案 + 回滚路径。
- trigger: 任务进入方案评估阶段
- verify: 本轮 eval.json 的 pass=true，且交付包含回滚说明
- result: $PASS_FLAG
- next_action: revise

EOF_STAGING
fi

echo "闭环完成: $SESSION_DIR"
echo "下一步：执行结束前可手动运行 session_end 校验"
