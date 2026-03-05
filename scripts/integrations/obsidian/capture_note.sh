#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TITLE=""
CONTENT=""
FOLDER="${OBSIDIAN_DEFAULT_FOLDER}"
APPEND_DAILY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --content)
      CONTENT="${2:-}"
      shift 2
      ;;
    --folder)
      FOLDER="${2:-}"
      shift 2
      ;;
    --daily)
      APPEND_DAILY=1
      shift
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "${OBSIDIAN_ENABLED:-0}" != "1" ]]; then
  echo "Obsidian 集成未启用（OBSIDIAN_ENABLED!=1）" >&2
  exit 1
fi
if ! obs_cli_exists; then
  echo "Obsidian CLI 不可用: $OBSIDIAN_CLI_BIN" >&2
  exit 1
fi

if [[ -z "$CONTENT" ]]; then
  if [[ ! -t 0 ]]; then
    CONTENT="$(cat)"
  fi
fi

if [[ -z "$CONTENT" ]]; then
  echo "content 不能为空（--content 或 stdin）" >&2
  exit 2
fi

if [[ "$APPEND_DAILY" == "1" ]]; then
  obs_run daily:append content="$CONTENT"
  obs_log "已追加到每日笔记"
  exit 0
fi

if [[ -z "$TITLE" ]]; then
  TITLE="Untitled $(date +%Y-%m-%d_%H-%M-%S)"
fi

slug="$(slugify "$TITLE")"
path="$FOLDER/$slug.md"
full_content="# $TITLE\n\n$CONTENT"

obs_run create path="$path" content="$full_content" overwrite
obs_log "已写入笔记: $path"
