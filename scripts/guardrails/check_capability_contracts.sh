#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"

if [[ ! -f "$REGISTRY" ]]; then
  echo "[capability] 缺少注册表: $REGISTRY"
  exit 1
fi

python3 - "$REGISTRY" <<'PY'
import sys

try:
    import yaml
except Exception as e:
    print(f"[capability] 缺少 PyYAML: {e}")
    sys.exit(1)

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

skills = data.get("skills", [])
if not isinstance(skills, list):
    print("[capability] skills 必须是数组")
    sys.exit(1)

ok = True
for s in skills:
    if not isinstance(s, dict):
        print("[capability] 存在非对象 skill")
        ok = False
        continue
    sid = str(s.get("skill_id", "")).strip() or "<unknown>"
    g = s.get("governance")
    if not isinstance(g, dict):
        print(f"[capability] {sid} 缺少 governance")
        ok = False
        continue

    for b in ["requires_auth", "read_only"]:
        if not isinstance(g.get(b), bool):
            print(f"[capability] {sid} governance.{b} 必须是布尔值")
            ok = False

    danger = str(g.get("danger_level", "")).strip().lower()
    if danger not in {"low", "medium", "high"}:
        print(f"[capability] {sid} governance.danger_level 非法: {danger}")
        ok = False

    cmd = str(g.get("health_check_cmd", "")).strip()
    if not cmd:
        print(f"[capability] {sid} governance.health_check_cmd 不能为空")
        ok = False

if not ok:
    sys.exit(1)
print("[capability] 契约校验通过")
PY
