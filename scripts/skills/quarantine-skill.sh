#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="${1:-}"
NAME="${2:-}"

if [[ -z "$SRC" || -z "$NAME" ]]; then
  echo "用法: bash scripts/skills/quarantine-skill.sh <src_dir> <skill-name>" >&2
  exit 2
fi
if [[ ! -d "$SRC" ]]; then
  echo "源目录不存在: $SRC" >&2
  exit 2
fi
if [[ ! "$NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "skill-name 非法: $NAME" >&2
  exit 2
fi

DEST="$ROOT_DIR/skills-core/quarantine/$NAME"
mkdir -p "$ROOT_DIR/skills-core/quarantine"
rm -rf "$DEST"
cp -r "$SRC" "$DEST"

echo "已放入隔离区: $DEST"
echo "下一步："
echo "1) 运行 check_skill_structure.sh 校验结构"
echo "2) 补齐 SKILL.md 与 manifest"
echo "3) 通过 promote-skill.sh 晋升"
