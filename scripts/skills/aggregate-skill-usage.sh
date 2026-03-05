#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVENTS_FILE="${1:-$ROOT_DIR/skills-core/usage/skill-route-events.ndjson}"
OUT_FILE="${2:-$ROOT_DIR/skills-core/skill-usage.json}"

mkdir -p "$(dirname "$EVENTS_FILE")"
mkdir -p "$(dirname "$OUT_FILE")"

if [[ ! -f "$EVENTS_FILE" ]]; then
  echo "{}" > "$OUT_FILE"
  echo "$OUT_FILE"
  exit 0
fi

python3 - "$EVENTS_FILE" "$OUT_FILE" <<'PY'
import json
import sys
from datetime import datetime, UTC, timedelta

events_file, out_file = sys.argv[1:]
now = datetime.now(UTC)
cutoff = now - timedelta(days=30)
agg = {}

with open(events_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except Exception:
            continue
        ts = str(e.get("timestamp", ""))
        try:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        except Exception:
            continue
        if dt < cutoff:
            continue
        sid = e.get("selected_skill")
        if not sid:
            # 未命中不计入 skill 单体，但保留总体路由失败统计价值
            continue
        row = agg.setdefault(sid, {"calls_30d": 0, "fail_30d": 0})
        row["calls_30d"] += 1
        if not e.get("matched", False):
            row["fail_30d"] += 1

out = {}
for sid, row in agg.items():
    calls = row["calls_30d"]
    fail = row["fail_30d"]
    out[sid] = {
        "calls_30d": calls,
        "fail_rate_30d": round(fail / calls, 4) if calls else 0.0,
    }

with open(out_file, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
print(out_file)
PY
