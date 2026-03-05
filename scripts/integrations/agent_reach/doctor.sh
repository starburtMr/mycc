#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CLI_BIN="$(ar_cli_bin)"
if [[ -z "$CLI_BIN" ]]; then
  ar_log "未找到 agent-reach CLI"
  exit 1
fi

"$CLI_BIN" doctor
