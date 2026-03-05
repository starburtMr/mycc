#!/usr/bin/env bash
set -euo pipefail

SESSION_DIR="${1:-}"
TOOL="${2:-}"
COMMAND="${3:-}"
STATUS="${4:-}"
NOTE="${5:-}"

if [[ -z "$SESSION_DIR" || -z "$TOOL" || -z "$COMMAND" || -z "$STATUS" ]]; then
  echo "用法: bash scripts/loop/log_tool_call.sh <session_dir> <tool> <command> <status> [note]" >&2
  exit 2
fi

mkdir -p "$SESSION_DIR"

python3 - "$SESSION_DIR/tool_calls.ndjson" "$TOOL" "$COMMAND" "$STATUS" "$NOTE" <<'PY'
import json
import sys
from datetime import datetime, UTC

path, tool, command, status, note = sys.argv[1:]
record = {
  "ts": datetime.now(UTC).replace(microsecond=0).isoformat().replace('+00:00','Z'),
  "tool": tool,
  "command": command,
  "status": status,
  "note": note or None,
}
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps(record, ensure_ascii=False) + "\n")
PY
