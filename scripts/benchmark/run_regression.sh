#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CASE_FILE="${1:-$ROOT_DIR/benchmarks/cases/smoke.list}"
OUT_FILE="${2:-$ROOT_DIR/benchmarks/last_regression.json}"

if [[ ! -f "$CASE_FILE" ]]; then
  echo "benchmark case 文件不存在: $CASE_FILE" >&2
  exit 2
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

pass_count=0
total=0

while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  name="${line%%|*}"
  cmd="${line#*|}"
  total=$((total + 1))
  log="/tmp/mycc_bench_${name}.log"
  if bash -lc "cd '$ROOT_DIR' && $cmd" >"$log" 2>&1; then
    status="passed"
    pass_count=$((pass_count + 1))
  else
    status="failed"
  fi
  python3 - "$tmp" "$name" "$status" "$cmd" "$log" <<'PY'
import json, os, sys
path, name, status, cmd, log = sys.argv[1:]
arr = []
if os.path.exists(path) and os.path.getsize(path) > 0:
    with open(path, "r", encoding="utf-8") as f:
        arr = json.load(f)
arr.append({
  "name": name,
  "status": status,
  "command": cmd,
  "log": log,
})
with open(path, "w", encoding="utf-8") as f:
    json.dump(arr, f, ensure_ascii=False, indent=2)
PY
done < "$CASE_FILE"

python3 - "$tmp" "$OUT_FILE" "$total" "$pass_count" <<'PY'
import json, sys
from datetime import datetime, UTC
tmp, out, total, passed = sys.argv[1:]
with open(tmp, "r", encoding="utf-8") as f:
    results = json.load(f)
total = int(total)
passed = int(passed)
obj = {
  "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
  "total": total,
  "passed": passed,
  "failed": total - passed,
  "pass_rate": round(passed / total, 4) if total else 0.0,
  "results": results,
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(obj, f, ensure_ascii=False, indent=2)
print(json.dumps(obj, ensure_ascii=False, indent=2))
PY

failed=$((total - pass_count))
if [[ "$failed" -gt 0 && "${BENCH_ALLOW_FAIL:-0}" != "1" ]]; then
  exit 1
fi
