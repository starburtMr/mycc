#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CFG_EXAMPLE="$ROOT_DIR/scripts/integrations/obsidian/config.env.example"
CFG_LOCAL="$ROOT_DIR/scripts/integrations/obsidian/config.local.sh"
STATE_DIR="$ROOT_DIR/scripts/integrations/obsidian/.state"

mkdir -p "$STATE_DIR"

# shellcheck disable=SC1090
source "$CFG_EXAMPLE"
if [[ -f "$CFG_LOCAL" ]]; then
  # shellcheck disable=SC1090
  source "$CFG_LOCAL"
fi

OBSIDIAN_ROOT_FOLDER="${OBSIDIAN_ROOT_FOLDER:-CC-AGENT-SPACE}"
OBSIDIAN_FOLDER_INBOX="${OBSIDIAN_FOLDER_INBOX:-$OBSIDIAN_ROOT_FOLDER/00-Inbox}"
OBSIDIAN_FOLDER_TASKS="${OBSIDIAN_FOLDER_TASKS:-$OBSIDIAN_ROOT_FOLDER/10-Tasks}"
OBSIDIAN_FOLDER_ADRS="${OBSIDIAN_FOLDER_ADRS:-$OBSIDIAN_ROOT_FOLDER/20-ADRs}"
OBSIDIAN_FOLDER_SOP="${OBSIDIAN_FOLDER_SOP:-$OBSIDIAN_ROOT_FOLDER/30-SOP}"
OBSIDIAN_FOLDER_PROFILE="${OBSIDIAN_FOLDER_PROFILE:-$OBSIDIAN_ROOT_FOLDER/40-Profile}"
OBSIDIAN_FOLDER_ARCHIVE="${OBSIDIAN_FOLDER_ARCHIVE:-$OBSIDIAN_ROOT_FOLDER/99-Archive}"

obs_log() {
  echo "[obsidian] $*"
}

obs_cli_exists() {
  command -v "$OBSIDIAN_CLI_BIN" >/dev/null 2>&1
}

obs_run() {
  if ! obs_cli_exists; then
    echo "Obsidian CLI 不存在: $OBSIDIAN_CLI_BIN" >&2
    return 1
  fi

  local base
  base="$(basename "$OBSIDIAN_CLI_BIN")"
  if [[ "$base" == "notesmd-cli" ]]; then
    "$OBSIDIAN_CLI_BIN" "$@"
  else
    if [[ -n "${OBSIDIAN_VAULT_NAME:-}" ]]; then
      "$OBSIDIAN_CLI_BIN" "vault=$OBSIDIAN_VAULT_NAME" "$@"
    else
      "$OBSIDIAN_CLI_BIN" "$@"
    fi
  fi
}

slugify() {
  local s="$1"
  s="$(echo "$s" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//')"
  if [[ -z "$s" ]]; then
    s="note-$(date +%Y%m%d%H%M%S)"
  fi
  echo "$s"
}

normalize_note_type() {
  local t="${1:-task}"
  t="$(echo "$t" | tr '[:upper:]' '[:lower:]')"
  case "$t" in
    inbox|task|adr|sop|profile|archive|knowledge|retro|template)
      echo "$t"
      ;;
    *)
      echo "task"
      ;;
  esac
}

route_folder_for_type() {
  local t
  t="$(normalize_note_type "$1")"
  case "$t" in
    inbox)
      echo "$OBSIDIAN_FOLDER_INBOX"
      ;;
    task|retro)
      echo "$OBSIDIAN_FOLDER_TASKS"
      ;;
    adr)
      echo "$OBSIDIAN_FOLDER_ADRS"
      ;;
    sop|knowledge|template)
      echo "$OBSIDIAN_FOLDER_SOP"
      ;;
    profile)
      echo "$OBSIDIAN_FOLDER_PROFILE"
      ;;
    archive)
      echo "$OBSIDIAN_FOLDER_ARCHIVE"
      ;;
    *)
      echo "$OBSIDIAN_FOLDER_TASKS"
      ;;
  esac
}
