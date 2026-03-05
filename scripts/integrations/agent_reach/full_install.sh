#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "$AGENT_REACH_ENABLED" != "1" ]]; then
  ar_log "适配层未启用。请在 config.local.sh 里设置 AGENT_REACH_ENABLED=1"
  exit 1
fi

CLI_BIN="$(ar_cli_bin)"
if [[ -z "$CLI_BIN" ]]; then
  ar_log "未找到 agent-reach CLI，请先执行 install.sh"
  exit 1
fi

ENV_MODE="${1:-auto}"
SAFE_FLAG="${2:-}"

ar_log "执行官方安装: agent-reach install --env=$ENV_MODE ${SAFE_FLAG}"
"$CLI_BIN" install --env="$ENV_MODE" ${SAFE_FLAG}

ar_log "执行 doctor 校验"
"$CLI_BIN" doctor
