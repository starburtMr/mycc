#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"
USAGE_FILE="$ROOT_DIR/skills-core/skill-usage.json"
OUT_FILE="$ROOT_DIR/skills-core/auto-downgrade-last.json"
MIN_CALLS=3
MAX_FAIL_RATE=0.3
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --usage-file) USAGE_FILE="${2:-}"; shift 2 ;;
    --out) OUT_FILE="${2:-}"; shift 2 ;;
    --min-calls) MIN_CALLS="${2:-3}"; shift 2 ;;
    --max-fail-rate) MAX_FAIL_RATE="${2:-0.3}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$REGISTRY" ]]; then
  echo "缺少注册表: $REGISTRY" >&2
  exit 1
fi

python3 - "$REGISTRY" "$USAGE_FILE" "$OUT_FILE" "$MIN_CALLS" "$MAX_FAIL_RATE" "$DRY_RUN" <<'PY'
import json
import os
import sys
from datetime import datetime, UTC

try:
    import yaml
except Exception as e:
    print(f"缺少 PyYAML: {e}", file=sys.stderr)
    raise SystemExit(1)

registry, usage_file, out_file, min_calls, max_fail_rate, dry_run = sys.argv[1:]
min_calls = int(min_calls)
max_fail_rate = float(max_fail_rate)
dry_run = dry_run == "1"

with open(registry, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}
skills = data.get("skills", [])
usage = {}
if os.path.isfile(usage_file):
    with open(usage_file, "r", encoding="utf-8") as f:
        usage = json.load(f)

changes = []
for s in skills:
    if not isinstance(s, dict):
        continue
    sid = str(s.get("skill_id", ""))
    lifecycle = str(s.get("lifecycle_status", "draft")).lower()
    routing = s.get("routing", {})
    if not isinstance(routing, dict):
        continue

    # 规则1：非 verified 禁止默认路由
    if lifecycle != "verified" and routing.get("default_enabled") is True:
        changes.append({"skill_id": sid, "action": "disable_default_non_verified"})
        routing["default_enabled"] = False

    # 规则2：低调用 + 高失败率自动降级
    u = usage.get(sid, {})
    calls = int(u.get("calls_30d", 0))
    fail_rate = float(u.get("fail_rate_30d", 0))
    if calls < min_calls and fail_rate > max_fail_rate:
        if lifecycle == "verified":
            s["lifecycle_status"] = "deprecated"
            routing["default_enabled"] = False
            changes.append({
                "skill_id": sid,
                "action": "deprecate_low_usage_high_fail",
                "calls_30d": calls,
                "fail_rate_30d": fail_rate,
            })

    # 规则3：低调用 + 高未命中率（通过平台汇总项触发提醒，不自动降级具体技能）
    # 注：_unmatched_* 由聚合脚本生成，此处仅保留输出语义一致，不写回 registry。

report = {
    "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "dry_run": dry_run,
    "min_calls": min_calls,
    "max_fail_rate": max_fail_rate,
    "changes": changes,
}

os.makedirs(os.path.dirname(out_file), exist_ok=True)
with open(out_file, "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)

if changes and not dry_run:
    data["skills"] = skills
    data["updated_at"] = datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    with open(registry, "w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, sort_keys=False, allow_unicode=True)

print(json.dumps(report, ensure_ascii=False, indent=2))
PY
