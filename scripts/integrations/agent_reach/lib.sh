#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
STATE_DIR="$ROOT_DIR/scripts/integrations/agent_reach/.state"
CONFIG_EXAMPLE="$ROOT_DIR/scripts/integrations/agent_reach/config.env.example"
CONFIG_LOCAL="$ROOT_DIR/scripts/integrations/agent_reach/config.local.sh"

mkdir -p "$STATE_DIR"

# 默认配置（受限模式）
AGENT_REACH_ENABLED="${AGENT_REACH_ENABLED:-0}"
AGENT_REACH_HOME="${AGENT_REACH_HOME:-$ROOT_DIR/.runtime/agent-reach}"
AGENT_REACH_REPO="${AGENT_REACH_REPO:-https://github.com/Panniantong/Agent-Reach.git}"
AGENT_REACH_REF="${AGENT_REACH_REF:-main}"
AGENT_REACH_NO_AGENT_CONFIG="${AGENT_REACH_NO_AGENT_CONFIG:-1}"
AGENT_REACH_DIAGNOSE_OUT_DEFAULT="${AGENT_REACH_DIAGNOSE_OUT_DEFAULT:-$ROOT_DIR/3-Thinking/sessions/agent-reach-diagnose.json}"

if [[ -f "$CONFIG_LOCAL" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_LOCAL"
fi

ar_log() {
  echo "[agent_reach] $*"
}

ar_require_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    ar_log "缺少 python3"
    exit 2
  fi
}

ar_repo_dir() {
  echo "$AGENT_REACH_HOME/repo"
}

ar_venv_python() {
  echo "$AGENT_REACH_HOME/.venv/bin/python"
}

ar_venv_pip() {
  echo "$AGENT_REACH_HOME/.venv/bin/pip"
}

ar_cli_bin() {
  # 兼容不同可执行名
  if [[ -x "$AGENT_REACH_HOME/.venv/bin/agent-reach" ]]; then
    echo "$AGENT_REACH_HOME/.venv/bin/agent-reach"
    return
  fi
  if [[ -x "$AGENT_REACH_HOME/.venv/bin/agent_reach" ]]; then
    echo "$AGENT_REACH_HOME/.venv/bin/agent_reach"
    return
  fi
  echo ""
}
