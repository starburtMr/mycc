#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OUT_FILE="${1:-$AGENT_REACH_DIAGNOSE_OUT_DEFAULT}"

REPO_DIR="$(ar_repo_dir)"
CLI_BIN="$(ar_cli_bin)"

repo_exists=false
venv_exists=false
cli_exists=false
install_state_exists=false
safe_mode=false
mcporter_exists=false
exa_ready=false

[[ -d "$REPO_DIR/.git" ]] && repo_exists=true
[[ -x "$(ar_venv_python)" ]] && venv_exists=true
[[ -n "$CLI_BIN" && -x "$CLI_BIN" ]] && cli_exists=true
[[ -f "$STATE_DIR/install_state.json" ]] && install_state_exists=true
[[ "$AGENT_REACH_NO_AGENT_CONFIG" == "1" ]] && safe_mode=true
command -v mcporter >/dev/null 2>&1 && mcporter_exists=true
if [[ "$mcporter_exists" == "true" ]]; then
  if mcporter list exa --schema --json >/dev/null 2>&1; then
    exa_ready=true
  fi
fi

pass=false
if [[ "$AGENT_REACH_ENABLED" == "1" && "$repo_exists" == "true" && "$venv_exists" == "true" && "$safe_mode" == "true" && "$mcporter_exists" == "true" && "$exa_ready" == "true" ]]; then
  pass=true
fi

mkdir -p "$(dirname "$OUT_FILE")"

python3 - "$OUT_FILE" "$AGENT_REACH_ENABLED" "$repo_exists" "$venv_exists" "$cli_exists" "$install_state_exists" "$safe_mode" "$mcporter_exists" "$exa_ready" "$pass" "$REPO_DIR" "$CLI_BIN" <<'PY'
import json
import sys
from datetime import datetime, UTC

(
    out_file,
    enabled,
    repo_exists,
    venv_exists,
    cli_exists,
    install_state_exists,
    safe_mode,
    mcporter_exists,
    exa_ready,
    passed,
    repo_dir,
    cli_bin,
) = sys.argv[1:]

as_bool = lambda s: str(s).lower() == "true"

data = {
    "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "integration": "agent-reach",
    "pass": as_bool(passed),
    "checks": {
        "enabled": enabled == "1",
        "repo_exists": as_bool(repo_exists),
        "venv_exists": as_bool(venv_exists),
        "cli_exists": as_bool(cli_exists),
        "install_state_exists": as_bool(install_state_exists),
        "safe_mode": as_bool(safe_mode),
        "mcporter_exists": as_bool(mcporter_exists),
        "exa_ready": as_bool(exa_ready),
    },
    "paths": {
        "repo_dir": repo_dir,
        "cli_bin": cli_bin,
    },
    "notes": [
        "当前是受限接入模式：禁止自动改 .claude/.codex 配置。"
    ],
}

with open(out_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(json.dumps(data, ensure_ascii=False, indent=2))
PY

ar_log "诊断报告已写入: $OUT_FILE"
