#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OBSIDIAN_REPO_PATH="${OBSIDIAN_REPO_PATH:-/mnt/data/obsidian}"
OBSIDIAN_GIT_AUTO_PUSH="${OBSIDIAN_GIT_AUTO_PUSH:-1}"
OBSIDIAN_GIT_BRANCH="${OBSIDIAN_GIT_BRANCH:-master}"
MESSAGE="${1:-obsidian: auto update}"

if [[ "$OBSIDIAN_GIT_AUTO_PUSH" != "1" ]]; then
  obs_log "已禁用自动 push（OBSIDIAN_GIT_AUTO_PUSH!=1）"
  exit 0
fi

if [[ ! -d "$OBSIDIAN_REPO_PATH/.git" ]]; then
  echo "Obsidian 仓库不存在或不是 git 目录: $OBSIDIAN_REPO_PATH" >&2
  exit 1
fi

if [[ -n "$(git -C "$OBSIDIAN_REPO_PATH" status --porcelain)" ]]; then
  if [[ -x "$ROOT_DIR/scripts/integrations/obsidian/validate_notes.sh" ]]; then
    bash "$ROOT_DIR/scripts/integrations/obsidian/validate_notes.sh"
  fi
  git -C "$OBSIDIAN_REPO_PATH" add -A
  if ! git -C "$OBSIDIAN_REPO_PATH" diff --cached --quiet; then
    git -C "$OBSIDIAN_REPO_PATH" commit -m "$MESSAGE" >/dev/null
  fi
fi

# 无新提交时直接返回成功
if [[ -z "$(git -C "$OBSIDIAN_REPO_PATH" log --oneline -1 2>/dev/null)" ]]; then
  exit 0
fi

git -C "$OBSIDIAN_REPO_PATH" push origin "$OBSIDIAN_GIT_BRANCH"
obs_log "已推送到远程: origin/$OBSIDIAN_GIT_BRANCH"
