#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "$AGENT_REACH_ENABLED" != "1" ]]; then
  ar_log "适配层未启用。请在 config.local.sh 里设置 AGENT_REACH_ENABLED=1"
  exit 1
fi

if [[ "$AGENT_REACH_NO_AGENT_CONFIG" != "1" ]]; then
  ar_log "拒绝执行：必须启用 AGENT_REACH_NO_AGENT_CONFIG=1（禁止自动改代理配置）"
  exit 1
fi

ar_require_python

REPO_DIR="$(ar_repo_dir)"
VENV_PY="$(ar_venv_python)"
VENV_PIP="$(ar_venv_pip)"

mkdir -p "$AGENT_REACH_HOME"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  ar_log "克隆仓库到 $REPO_DIR"
  git clone --depth 1 --branch "$AGENT_REACH_REF" "$AGENT_REACH_REPO" "$REPO_DIR"
else
  ar_log "仓库已存在，跳过克隆"
fi

if [[ ! -x "$VENV_PY" ]]; then
  ar_log "创建虚拟环境"
  python3 -m venv "$AGENT_REACH_HOME/.venv"
fi

ar_log "安装依赖"
"$VENV_PIP" install --upgrade pip >/dev/null
"$VENV_PIP" install -e "$REPO_DIR"

COMMIT="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
python3 - "$STATE_DIR/install_state.json" "$COMMIT" <<'PY'
import json
import sys
from datetime import datetime, UTC

path, commit = sys.argv[1:]
data = {
    "installed_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "commit": commit,
    "restricted_mode": True,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

ar_log "安装完成（受限模式）"
