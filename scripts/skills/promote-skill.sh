#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NAME="${1:-}"

if [[ -z "$NAME" ]]; then
  echo "用法: bash scripts/skills/promote-skill.sh <skill-name>" >&2
  exit 2
fi
if [[ ! "$NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "skill-name 非法: $NAME" >&2
  exit 2
fi

SRC="$ROOT_DIR/skills-core/quarantine/$NAME"
DST="$ROOT_DIR/skills-core/skills/$NAME"
if [[ ! -d "$SRC" ]]; then
  echo "隔离区不存在该 skill: $SRC" >&2
  exit 2
fi

mkdir -p "$ROOT_DIR/skills-core/skills"
rm -rf "$DST"
mv "$SRC" "$DST"

bash "$ROOT_DIR/scripts/guardrails/check_skill_structure.sh"

echo "已晋升到主技能区: $DST"
echo "下一步：调用 register-skill.sh 注册并设置 lifecycle_status=verified（通过验证后）"
