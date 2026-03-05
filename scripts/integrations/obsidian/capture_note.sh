#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TITLE=""
CONTENT=""
FOLDER=""
APPEND_DAILY=0
NOTE_TYPE="${OBSIDIAN_DEFAULT_TYPE:-task}"
NOTE_STATUS="${OBSIDIAN_DEFAULT_STATUS:-active}"
NOTE_TAGS="${OBSIDIAN_DEFAULT_TAGS:-cc,obsidian}"
NOTE_SOURCE="${OBSIDIAN_NOTE_SOURCE:-codex}"
NOTE_OWNER="${OBSIDIAN_NOTE_OWNER:-cc}"
NOTE_ID=""

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
    --type)
      NOTE_TYPE="${2:-}"
      shift 2
      ;;
    --status)
      NOTE_STATUS="${2:-}"
      shift 2
      ;;
    --tags)
      NOTE_TAGS="${2:-}"
      shift 2
      ;;
    --id)
      NOTE_ID="${2:-}"
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
  if [[ "$(basename "$OBSIDIAN_CLI_BIN")" == "notesmd-cli" ]]; then
    echo "notesmd-cli 暂不支持 daily append，建议改用 --title 写入单独笔记" >&2
    exit 2
  fi
  obs_run daily:append content="$CONTENT"
  obs_log "已追加到每日笔记"
  exit 0
fi

if [[ -z "$TITLE" ]]; then
  TITLE="Untitled $(date +%Y-%m-%d_%H-%M-%S)"
fi

NOTE_TYPE="$(normalize_note_type "$NOTE_TYPE")"
if [[ -z "$FOLDER" ]]; then
  FOLDER="$(route_folder_for_type "$NOTE_TYPE")"
fi

slug="$(slugify "$TITLE")"
path="$FOLDER/$slug.md"
if [[ -z "$NOTE_ID" ]]; then
  NOTE_ID="N-$(date +%Y%m%d%H%M%S)-$slug"
fi
tags_inline="$(echo "$NOTE_TAGS" | sed 's/[[:space:]]//g')"
today="$(date +%F)"

full_content="$CONTENT"
if [[ "${OBSIDIAN_ENFORCE_FRONTMATTER:-1}" == "1" ]]; then
  if ! printf "%s" "$CONTENT" | head -n 1 | rg -q '^---$'; then
    full_content="---\nid: $NOTE_ID\ntitle: $TITLE\ntype: $NOTE_TYPE\nstatus: $NOTE_STATUS\ntags: [$tags_inline]\nsource: $NOTE_SOURCE\nowner: $NOTE_OWNER\nupdated: $today\n---\n\n# $TITLE\n\n$CONTENT"
  fi
fi

if [[ -d "${OBSIDIAN_REPO_PATH:-}" ]]; then
  mkdir -p "${OBSIDIAN_REPO_PATH}/$FOLDER"
fi

if [[ "$(basename "$OBSIDIAN_CLI_BIN")" == "notesmd-cli" ]]; then
  if [[ -n "${OBSIDIAN_VAULT_NAME:-}" ]]; then
    obs_run create "$path" -v "$OBSIDIAN_VAULT_NAME" -c "$full_content" -o
  else
    obs_run create "$path" -c "$full_content" -o
  fi
else
  obs_run create path="$path" content="$full_content" overwrite
fi
obs_log "已写入笔记: $path"

# 每次写入后自动推送到远程仓库
if [[ "${OBSIDIAN_SKIP_AUTO_PUSH:-0}" != "1" ]]; then
  bash "$ROOT_DIR/scripts/integrations/obsidian/push_git.sh" "obsidian: add note $slug"
fi
