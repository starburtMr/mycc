#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_REPO_DIR="${1:-}"
SOURCE_URL="${2:-}"

if [[ -z "$SRC_REPO_DIR" ]]; then
  echo "用法: bash scripts/skills/import-repo-skills.sh <repo_dir> [source_url]" >&2
  exit 2
fi
if [[ ! -d "$SRC_REPO_DIR" ]]; then
  echo "仓库目录不存在: $SRC_REPO_DIR" >&2
  exit 2
fi

QUARANTINE_ROOT="$ROOT_DIR/skills-core/quarantine"
mkdir -p "$QUARANTINE_ROOT"

import_one() {
  local src_name="$1"
  local target_name="$2"
  local src="$SRC_REPO_DIR/$src_name"
  local dst="$QUARANTINE_ROOT/$target_name"

  if [[ ! -d "$src" ]]; then
    echo "[skip] 未找到目录: $src"
    return 0
  fi

  rm -rf "$dst"
  mkdir -p "$dst"/{agents,scripts,references,assets}
  touch "$dst"/agents/.gitkeep "$dst"/scripts/.gitkeep "$dst"/references/.gitkeep "$dst"/assets/.gitkeep

  if [[ -f "$src/SKILL.md" ]]; then
    cp "$src/SKILL.md" "$dst/SKILL.md"
  else
    cat > "$dst/SKILL.md" <<EOF
---
name: $target_name
description: 从第三方仓库导入到隔离区的技能，待评审与改造。
---

# $target_name

此技能由导入脚本创建占位，后续需补全内容。
EOF
  fi

  if [[ -d "$src/scripts" ]]; then
    cp -r "$src/scripts/." "$dst/scripts/" || true
  fi
  if [[ -d "$src/references" ]]; then
    cp -r "$src/references/." "$dst/references/" || true
  fi
  if [[ -d "$src/assets" ]]; then
    cp -r "$src/assets/." "$dst/assets/" || true
  fi
  if [[ -d "$src/agents" ]]; then
    cp -r "$src/agents/." "$dst/agents/" || true
  fi

  cat > "$dst/IMPORT_META.md" <<EOF
# 导入元数据

- imported_at: $(date -u +%FT%TZ)
- source_repo_dir: $SRC_REPO_DIR
- source_path: $src_name
- source_url: ${SOURCE_URL:-unknown}
- status: quarantined
- next_step:
  1. 运行 check_skill_structure.sh（仅结构）
  2. 人工审查 SKILL.md 与 scripts 权限边界
  3. 按需 promote + register
EOF

  echo "[ok] 已导入: $target_name -> $dst"
}

# 当前针对 ThendCN/ai-team-skills 的三个核心目录
import_one "ai-team" "ai-team"
import_one "codex-agent" "codex-agent"
import_one "gemini-agent" "gemini-agent"

echo "导入完成。隔离区路径：$QUARANTINE_ROOT"
