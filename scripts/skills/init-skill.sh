#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/skills-core/templates/skill-package"
SKILLS_DIR="$ROOT_DIR/skills-core/skills"

SKILL_NAME="${1:-}"
if [[ -z "$SKILL_NAME" ]]; then
  echo "用法: bash scripts/skills/init-skill.sh <skill-name>" >&2
  exit 2
fi

if [[ ! "$SKILL_NAME" =~ ^[a-z0-9-]+$ ]]; then
  echo "skill-name 非法（仅允许小写字母/数字/中划线）: $SKILL_NAME" >&2
  exit 2
fi

DEST="$SKILLS_DIR/$SKILL_NAME"
mkdir -p "$DEST"/{agents,scripts,references,assets}
touch "$DEST"/agents/.gitkeep "$DEST"/scripts/.gitkeep "$DEST"/references/.gitkeep "$DEST"/assets/.gitkeep

if [[ ! -f "$DEST/SKILL.md" ]]; then
  sed "s/your-skill-name/$SKILL_NAME/g" "$TEMPLATE_DIR/SKILL.md.template" > "$DEST/SKILL.md"
fi

if [[ ! -f "$DEST/manifest.yaml" ]]; then
  sed "s/your-skill-id/$SKILL_NAME/g; s#skills-core/skills/your-skill-id/SKILL.md#skills-core/skills/$SKILL_NAME/SKILL.md#g" \
    "$TEMPLATE_DIR/manifest.yaml.template" > "$DEST/manifest.yaml"
fi

echo "已初始化 skill 目录: $DEST"
echo "下一步："
echo "1) 编辑 $DEST/SKILL.md"
echo "2) 用 register-skill.sh 注册到 registry"
