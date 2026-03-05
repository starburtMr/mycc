#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILLS_DIR="$ROOT_DIR/skills-core/skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "[skills-structure] 缺少目录: $SKILLS_DIR" >&2
  exit 1
fi

fail=0
shopt -s nullglob
for d in "$SKILLS_DIR"/*; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"

  if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
    echo "[skills-structure] skill 目录名非法: $name（仅允许小写字母/数字/中划线）" >&2
    fail=1
  fi

  if [[ ! -f "$d/SKILL.md" ]]; then
    echo "[skills-structure] 缺少 SKILL.md: $name" >&2
    fail=1
  else
    if ! rg -n '^name:\s*\S+' "$d/SKILL.md" >/dev/null; then
      echo "[skills-structure] SKILL.md 缺少 frontmatter.name: $name" >&2
      fail=1
    fi
    if ! rg -n '^description:\s*\S+' "$d/SKILL.md" >/dev/null; then
      echo "[skills-structure] SKILL.md 缺少 frontmatter.description: $name" >&2
      fail=1
    fi
  fi

  for sub in agents scripts references assets; do
    if [[ ! -d "$d/$sub" ]]; then
      echo "[skills-structure] 缺少子目录 $sub: $name" >&2
      fail=1
    fi
  done
done

if [[ $fail -ne 0 ]]; then
  echo "[skills-structure] 校验失败" >&2
  exit 1
fi

echo "[skills-structure] 校验通过"
