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

  if [[ -n "${OBSIDIAN_VAULT_NAME:-}" ]]; then
    "$OBSIDIAN_CLI_BIN" "vault=$OBSIDIAN_VAULT_NAME" "$@"
  else
    "$OBSIDIAN_CLI_BIN" "$@"
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
