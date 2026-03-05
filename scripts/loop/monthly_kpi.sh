#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONTH="${1:-$(date +%Y-%m)}"
OUT_FILE="${2:-$ROOT_DIR/3-Thinking/sessions/kpi-$MONTH.json}"

python3 - "$ROOT_DIR" "$MONTH" "$OUT_FILE" <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, UTC

root, month, out_file = sys.argv[1:]
sessions_dir = os.path.join(root, "3-Thinking", "sessions")

total = passed = 0
turns = 0
token_cost = None

if os.path.isdir(sessions_dir):
    for sid in os.listdir(sessions_dir):
        p = os.path.join(sessions_dir, sid, "eval.json")
        if not os.path.isfile(p):
            continue
        try:
            with open(p, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        ts = data.get("generated_at", "")
        if not str(ts).startswith(month):
            continue
        total += 1
        if data.get("pass") is True:
            passed += 1
        tool_log = os.path.join(sessions_dir, sid, "tool_calls.ndjson")
        if os.path.isfile(tool_log):
            with open(tool_log, "r", encoding="utf-8") as f:
                turns += sum(1 for _ in f)

rollback_count = 0
try:
    out = subprocess.check_output(
        ["git", "-C", root, "log", "--since", f"{month}-01", "--pretty=%s"],
        text=True,
        stderr=subprocess.DEVNULL,
    )
    rollback_count = sum(1 for line in out.splitlines() if "rollback" in line.lower() or "回滚" in line)
except Exception:
    rollback_count = 0

obj = {
    "month": month,
    "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "kpi": {
        "success_rate": round(passed / total, 4) if total else 0.0,
        "avg_turns": round(turns / total, 2) if total else 0.0,
        "token_cost": token_cost,
        "rollback_count": rollback_count,
    },
    "raw": {
        "sessions_total": total,
        "sessions_passed": passed,
        "tool_turns_total": turns,
    },
}
os.makedirs(os.path.dirname(out_file), exist_ok=True)
with open(out_file, "w", encoding="utf-8") as f:
    json.dump(obj, f, ensure_ascii=False, indent=2)
print(json.dumps(obj, ensure_ascii=False, indent=2))
PY
