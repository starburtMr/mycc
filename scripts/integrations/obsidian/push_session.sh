#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/scripts/integrations/obsidian/lib.sh"

SESSION_DIR="${1:-}"

if [[ -z "$SESSION_DIR" ]]; then
  echo "用法: bash scripts/integrations/obsidian/push_session.sh <session_dir>" >&2
  exit 2
fi

if [[ ! -d "$SESSION_DIR" ]]; then
  echo "会话目录不存在: $SESSION_DIR" >&2
  exit 2
fi

if [[ "${OBSIDIAN_ENABLED:-0}" != "1" ]]; then
  echo "Obsidian 集成未启用（OBSIDIAN_ENABLED!=1）" >&2
  exit 1
fi
if ! obs_cli_exists; then
  echo "Obsidian CLI 不可用: $OBSIDIAN_CLI_BIN" >&2
  exit 1
fi

sid="$(basename "$SESSION_DIR")"
manifest="$SESSION_DIR/run_manifest.json"
eval_file="$SESSION_DIR/eval.json"
reflection="$SESSION_DIR/reflection.md"

run_id=""
if [[ -f "$manifest" ]]; then
  run_id="$(python3 - "$manifest" <<'PY'
import json,sys
p=sys.argv[1]
try:
    d=json.load(open(p,'r',encoding='utf-8'))
    print(d.get('run_id',''))
except Exception:
    print('')
PY
)"
fi

summary=""
if [[ -f "$eval_file" ]]; then
  summary="$(python3 - "$eval_file" <<'PY'
import json,sys
p=sys.argv[1]
try:
    d=json.load(open(p,'r',encoding='utf-8'))
    print(f"pass={d.get('pass')} style_score={d.get('scores',{}).get('style_score')}")
except Exception:
    print('pass=unknown')
PY
)"
fi

body="- session_id: $sid\n- run_id: ${run_id:-unknown}\n- eval: ${summary:-unknown}\n- pushed_at: $(date -u +%FT%TZ)\n\n"
if [[ -f "$reflection" ]]; then
  body+="## Reflection\n\n$(cat "$reflection")"
else
  body+="(无 reflection.md)"
fi

bash "$ROOT_DIR/scripts/integrations/obsidian/capture_note.sh" \
  --title "Session $sid" \
  --folder "${OBSIDIAN_DEFAULT_FOLDER}/Sessions" \
  --content "$body"

obs_log "已沉淀会话到 Obsidian: $sid"
