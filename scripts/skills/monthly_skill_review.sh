#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONTH="${1:-$(date +%Y-%m)}"
OUT_FILE="${2:-$ROOT_DIR/skills-core/monthly-skill-review-$MONTH.md}"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"
USAGE_FILE="${3:-$ROOT_DIR/skills-core/skill-usage.json}"

python3 - "$REGISTRY" "$OUT_FILE" "$MONTH" "$USAGE_FILE" <<'PY'
import sys
from datetime import datetime, UTC

try:
    import yaml
except Exception as e:
    print(f"缺少 PyYAML: {e}", file=sys.stderr)
    raise SystemExit(1)

import json

registry, out_file, month, usage_file = sys.argv[1:]
with open(registry, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}
usage = {}
try:
    with open(usage_file, "r", encoding="utf-8") as f:
        usage = json.load(f)
except Exception:
    usage = {}

skills = data.get("skills", [])
lines = [
    f"# Skill 月度评审（{month})",
    "",
    f"- generated_at: {datetime.now(UTC).replace(microsecond=0).isoformat().replace('+00:00','Z')}",
    "- 规则：unverified/draft 不进入默认路由；高风险低复用进入淘汰候选。",
    "",
    "## 全量清单",
    "",
    "| skill_id | lifecycle | default_enabled | blast_radius | calls_30d | fail_rate_30d | 建议 |",
    "|---|---|---|---|---:|---:|---|",
]

for s in skills:
    sid = s.get("skill_id", "")
    lifecycle = str(s.get("lifecycle_status", "draft"))
    routing = s.get("routing", {}) if isinstance(s.get("routing"), dict) else {}
    governance = s.get("governance", {}) if isinstance(s.get("governance"), dict) else {}
    default_enabled = routing.get("default_enabled")
    blast = governance.get("blast_radius", "readonly")
    u = usage.get(sid, {})
    calls = int(u.get("calls_30d", 0))
    fail_rate = float(u.get("fail_rate_30d", 0.0))
    suggestion = "保持"
    if lifecycle != "verified":
        suggestion = "保持禁用默认路由"
    if blast == "external_side_effect" and lifecycle != "verified":
        suggestion = "优先隔离/降级"
    if calls < 3 and fail_rate > 0.3:
        suggestion = "降级候选（低调用高失败）"
    lines.append(f"| {sid} | {lifecycle} | {default_enabled} | {blast} | {calls} | {fail_rate:.2f} | {suggestion} |")

with open(out_file, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print(out_file)
PY
