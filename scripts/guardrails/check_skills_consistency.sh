#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT_DIR/skills-core/skill-registry.yaml"

if [[ ! -f "$REGISTRY" ]]; then
  echo "[skills] 缺少注册表: $REGISTRY"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[skills] 缺少 python3，无法执行技能一致性校验"
  exit 1
fi

python3 - "$ROOT_DIR" "$REGISTRY" <<'PY'
import os
import re
import sys

try:
    import yaml
except Exception as e:  # pragma: no cover
    print(f"[skills] 缺少 PyYAML: {e}")
    sys.exit(1)

root, registry_path = sys.argv[1], sys.argv[2]

with open(registry_path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}

skills = data.get("skills", [])
if not isinstance(skills, list):
    print("[skills] registry.skills 必须是数组")
    sys.exit(1)

fail = 0
seen = set()
pattern = re.compile(r"^[a-z0-9._-]+$")

for item in skills:
    if not isinstance(item, dict):
        print("[skills] skills 项存在非对象元素")
        fail = 1
        continue

    sid = str(item.get("skill_id", "")).strip()
    if not sid or not pattern.fullmatch(sid):
        print(f"[skills] skill_id 非法: {sid}")
        fail = 1
        continue
    if sid in seen:
        print(f"[skills] skill_id 重复: {sid}")
        fail = 1
    seen.add(sid)

    routing = item.get("routing", {})
    if not isinstance(routing, dict):
        print(f"[skills] {sid} routing 缺失或非法")
        fail = 1
        continue

    supports_codex = routing.get("supports_codex")
    supports_claude = routing.get("supports_claude")
    if not isinstance(supports_codex, bool) or not isinstance(supports_claude, bool):
        print(f"[skills] {sid} supports_codex/supports_claude 必须是布尔值")
        fail = 1

    has_any_platform = bool(supports_codex or supports_claude)
    if not has_any_platform:
        print(f"[skills] {sid} 没有可用平台")
        fail = 1

    for key in ["entry_shared", "entry_codex", "entry_claude"]:
        path = str(routing.get(key, "")).strip()
        if not path:
            continue
        abs_path = os.path.join(root, path)
        if not os.path.exists(abs_path):
            print(f"[skills] {sid} 路径不存在: {path}")
            fail = 1

    if supports_codex and not str(routing.get("entry_codex", "")).strip() and not str(routing.get("entry_shared", "")).strip():
        print(f"[skills] {sid} 标记支持 Codex，但无 entry_codex/entry_shared")
        fail = 1
    if supports_claude and not str(routing.get("entry_claude", "")).strip() and not str(routing.get("entry_shared", "")).strip():
        print(f"[skills] {sid} 标记支持 Claude，但无 entry_claude/entry_shared")
        fail = 1

if fail:
    sys.exit(1)

print("[skills] 一致性校验通过")
PY
