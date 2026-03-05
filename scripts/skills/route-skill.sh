#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"
PLATFORM="codex"
QUERY=""
OUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="${2:-}"; shift 2 ;;
    --query) QUERY="${2:-}"; shift 2 ;;
    --out) OUT_FILE="${2:-}"; shift 2 ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo "用法: bash scripts/skills/route-skill.sh --platform <codex|claude> --query \"<意图>\" [--out <json>]" >&2
  exit 2
fi
if [[ ! "$PLATFORM" =~ ^(codex|claude)$ ]]; then
  echo "--platform 仅支持 codex|claude" >&2
  exit 2
fi
if [[ ! -f "$REGISTRY" ]]; then
  echo "缺少注册表: $REGISTRY" >&2
  exit 1
fi

if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="$ROOT_DIR/3-Thinking/sessions/skill-route-$(date +%Y%m%dT%H%M%S).json"
fi
mkdir -p "$(dirname "$OUT_FILE")"

python3 - "$ROOT_DIR" "$REGISTRY" "$PLATFORM" "$QUERY" "$OUT_FILE" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, UTC

try:
    import yaml
except Exception as e:
    print(f"缺少 PyYAML: {e}", file=sys.stderr)
    raise SystemExit(1)

root, registry, platform, query, out_file = sys.argv[1:]
with open(registry, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

tokens = [t for t in re.split(r"[\s,;，。/|:_-]+", query.lower()) if t]
skills = data.get("skills", [])
candidates = []
for s in skills:
    if not isinstance(s, dict):
        continue
    routing = s.get("routing", {}) if isinstance(s.get("routing"), dict) else {}
    lifecycle = str(s.get("lifecycle_status", "")).lower()
    if lifecycle != "verified":
        continue
    if routing.get("default_enabled") is not True:
        continue
    if platform == "codex" and routing.get("supports_codex") is not True:
        continue
    if platform == "claude" and routing.get("supports_claude") is not True:
        continue

    text = " ".join([
        str(s.get("skill_id", "")),
        str(s.get("display_name", "")),
        str(s.get("category", "")),
        " ".join([str(n) for n in s.get("notes", [])]) if isinstance(s.get("notes"), list) else "",
    ]).lower()
    shared = str(routing.get("entry_shared", "")).strip()
    if shared:
        p = os.path.join(root, shared)
        if os.path.isfile(p):
            try:
                with open(p, "r", encoding="utf-8") as f:
                    text += " " + f.read(2000).lower()
            except Exception:
                pass
    score = sum(1 for t in tokens if t in text)
    candidates.append({
        "skill_id": s.get("skill_id", ""),
        "score": score,
        "entry_shared": routing.get("entry_shared", ""),
        "entry_platform": routing.get(f"entry_{platform}", ""),
    })

candidates.sort(key=lambda x: (-x["score"], x["skill_id"]))
selected = candidates[0] if candidates and candidates[0]["score"] > 0 else None
result = {
    "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00","Z"),
    "platform": platform,
    "query": query,
    "selected": selected,
    "candidates": candidates,
}
with open(out_file, "w", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)
print(json.dumps(result, ensure_ascii=False, indent=2))
PY
