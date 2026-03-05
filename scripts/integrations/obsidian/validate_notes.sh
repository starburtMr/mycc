#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OBSIDIAN_REPO_PATH="${OBSIDIAN_REPO_PATH:-/mnt/data/obsidian}"
OBSIDIAN_MANAGED_ROOT="${OBSIDIAN_ROOT_FOLDER:-CC-AGENT-SPACE}"
OBSIDIAN_REQUIRE_CHINESE="${OBSIDIAN_REQUIRE_CHINESE:-1}"
OBSIDIAN_ENFORCE_FRONTMATTER="${OBSIDIAN_ENFORCE_FRONTMATTER:-1}"

if [[ ! -d "$OBSIDIAN_REPO_PATH/.git" ]]; then
  echo "Obsidian 仓库不存在或不是 git 目录: $OBSIDIAN_REPO_PATH" >&2
  exit 1
fi

status_lines="$(git -C "$OBSIDIAN_REPO_PATH" status --porcelain)"
if [[ -z "$status_lines" ]]; then
  obs_log "无变更，跳过校验"
  exit 0
fi

fail=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  file="${line:3}"
  [[ "$file" == *.md ]] || continue
  [[ "$file" == "$OBSIDIAN_MANAGED_ROOT/"* ]] || continue
  [[ -f "$OBSIDIAN_REPO_PATH/$file" ]] || continue

  abs_file="$OBSIDIAN_REPO_PATH/$file"
  if [[ "$OBSIDIAN_ENFORCE_FRONTMATTER" == "1" ]]; then
    if ! awk 'NR==1 {ok=($0=="---"); next} ok && $0=="---" {exit 0} END {exit 1}' "$abs_file"; then
      echo "[校验失败] 缺少 Frontmatter: $file" >&2
      fail=1
      continue
    fi

    fm="$(awk 'NR==1 && $0=="---" {in=1; next} in && $0=="---" {exit} in {print}' "$abs_file")"
    for key in id title type status tags source owner updated; do
      if ! printf "%s\n" "$fm" | rg -n "^${key}:[[:space:]]*\\S+" >/dev/null; then
        echo "[校验失败] Frontmatter 缺少字段 ${key}: $file" >&2
        fail=1
      fi
    done

    t="$(printf "%s\n" "$fm" | sed -n 's/^type:[[:space:]]*//p' | head -n1 | tr '[:upper:]' '[:lower:]')"
    if [[ ! "$t" =~ ^(inbox|task|adr|sop|profile|archive|knowledge|retro|template)$ ]]; then
      echo "[校验失败] type 非法($t): $file" >&2
      fail=1
    fi

    s="$(printf "%s\n" "$fm" | sed -n 's/^status:[[:space:]]*//p' | head -n1 | tr '[:upper:]' '[:lower:]')"
    if [[ ! "$s" =~ ^(draft|active|done|archived)$ ]]; then
      echo "[校验失败] status 非法($s): $file" >&2
      fail=1
    fi
  fi

  if [[ "$OBSIDIAN_REQUIRE_CHINESE" == "1" ]]; then
    if ! rg -q '[一-龥]' "$abs_file"; then
      echo "[校验失败] 笔记缺少中文内容: $file" >&2
      fail=1
    fi
  fi
done <<< "$status_lines"

if [[ $fail -ne 0 ]]; then
  echo "Obsidian 笔记校验未通过，请修复后再 push。" >&2
  exit 1
fi

obs_log "笔记校验通过"
