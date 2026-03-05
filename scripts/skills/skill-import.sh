#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"
MANIFEST="${1:-}"

if [[ -z "$MANIFEST" ]]; then
  echo "用法: scripts/skills/skill-import.sh <manifest.yaml>"
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "manifest 不存在: $MANIFEST"
  exit 2
fi

if [[ ! -f "$REGISTRY" ]]; then
  echo "注册表不存在: $REGISTRY"
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "缺少 python3，无法处理 yaml"
  exit 2
fi

python3 - "$REGISTRY" "$MANIFEST" <<'PY'
import datetime
import re
import sys

try:
    import yaml
except Exception as e:  # pragma: no cover
    print(f"缺少 PyYAML: {e}")
    sys.exit(2)

registry_path, manifest_path = sys.argv[1], sys.argv[2]

with open(registry_path, "r", encoding="utf-8") as f:
    registry = yaml.safe_load(f) or {}
with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = yaml.safe_load(f) or {}

required_top = ["skill_id", "display_name", "category", "source", "routing", "quality"]
for key in required_top:
    if key not in manifest:
        print(f"manifest 缺少字段: {key}")
        sys.exit(2)

skill_id = str(manifest["skill_id"]).strip()
if not re.fullmatch(r"[a-z0-9._-]+", skill_id):
    print(f"skill_id 非法: {skill_id}")
    sys.exit(2)

routing = manifest.get("routing", {})
for key in ["supports_codex", "supports_claude"]:
    if key not in routing or not isinstance(routing[key], bool):
        print(f"routing.{key} 缺失或不是布尔值")
        sys.exit(2)

if "skills" not in registry or not isinstance(registry["skills"], list):
    registry["skills"] = []

replaced = False
for idx, item in enumerate(registry["skills"]):
    if isinstance(item, dict) and str(item.get("skill_id", "")).strip() == skill_id:
        registry["skills"][idx] = manifest
        replaced = True
        break

if not replaced:
    registry["skills"].append(manifest)

registry["skills"] = sorted(
    registry["skills"],
    key=lambda x: str(x.get("skill_id", "")) if isinstance(x, dict) else "",
)
registry["updated_at"] = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
registry["version"] = int(registry.get("version", 1))

with open(registry_path, "w", encoding="utf-8") as f:
    yaml.safe_dump(registry, f, sort_keys=False, allow_unicode=True)

print(f"导入成功: {skill_id} ({'更新' if replaced else '新增'})")
PY
