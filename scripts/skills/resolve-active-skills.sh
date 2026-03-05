#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"
PLATFORM="${1:-codex}"

if [[ ! -f "$REGISTRY" ]]; then
  echo "缺少注册表: $REGISTRY" >&2
  exit 1
fi

python3 - "$REGISTRY" "$PLATFORM" <<'PY'
import sys
try:
    import yaml
except Exception as e:
    print(f"缺少 PyYAML: {e}", file=sys.stderr)
    raise SystemExit(1)

path, platform = sys.argv[1:]
with open(path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

skills = data.get("skills", [])
for s in skills:
    if not isinstance(s, dict):
        continue
    lifecycle = str(s.get("lifecycle_status", "")).lower()
    routing = s.get("routing", {}) if isinstance(s.get("routing"), dict) else {}
    if lifecycle != "verified":
        continue
    if routing.get("default_enabled") is not True:
        continue
    if platform == "codex" and routing.get("supports_codex") is not True:
        continue
    if platform == "claude" and routing.get("supports_claude") is not True:
        continue
    print(s.get("skill_id", ""))
PY
