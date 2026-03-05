#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

QUERY=""
TASK_FILE=""
PROJECT=""
OUT_FILE=""
MODE="${EVOMAP_SEARCH_MODE:-hybrid}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      QUERY="${2:-}"
      shift 2
      ;;
    --task)
      TASK_FILE="${2:-}"
      shift 2
      ;;
    --project)
      PROJECT="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo "用法: bash scripts/integrations/web_search.sh --query <text> [--task tasks/active/<task>.md] [--project <name>] [--out <path>] [--mode hybrid|internal|web]" >&2
  exit 2
fi

if [[ -n "$TASK_FILE" && ! "$TASK_FILE" =~ ^tasks/active/[^/]+\.md$ ]]; then
  echo "--task 路径非法，仅允许 tasks/active/*.md" >&2
  exit 2
fi
if [[ -n "$TASK_FILE" && ! -f "$ROOT_DIR/$TASK_FILE" ]]; then
  echo "任务文件不存在: $ROOT_DIR/$TASK_FILE" >&2
  exit 2
fi

# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/evomap/lib.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/integrations/agent_reach/lib.sh"

if [[ -z "$PROJECT" && -n "$TASK_FILE" ]]; then
  PROJECT="$(extract_task_field "$ROOT_DIR/$TASK_FILE" "project")"
fi

if [[ -z "$OUT_FILE" ]]; then
  if [[ -n "$PROJECT" ]]; then
    OUT_FILE="$ROOT_DIR/2-Projects/$PROJECT/context/WEB_SEARCH_LAST.json"
  else
    OUT_FILE="$ROOT_DIR/3-Thinking/sessions/web-search-$(date +%Y%m%dT%H%M%S).json"
  fi
fi
mkdir -p "$(dirname "$OUT_FILE")"

EVOMAP_OK=false
EVOMAP_RESP='{}'
EVOMAP_SUMMARY=''
EVOMAP_INTERNAL=0
EVOMAP_WEB=0
EVOMAP_ERROR=''

if [[ "${EVOMAP_ENABLED:-0}" == "1" ]]; then
  if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    sender_id="$(ensure_query_sender_id)"
    req_payload="$(cat <<JSON
{
  \"sender_id\": \"$sender_id\",
  \"query\": $(jq -Rn --arg q "$QUERY" '$q'),
  \"mode\": \"$MODE\"
}
JSON
)"

    resp="$(evomap_post_json "/a2a/skill/search" "$req_payload" || true)"
    if [[ -n "$resp" ]] && echo "$resp" | jq . >/dev/null 2>&1; then
      EVOMAP_RESP="$resp"
      EVOMAP_SUMMARY="$(echo "$resp" | jq -r '.summary // ""')"
      EVOMAP_INTERNAL="$(echo "$resp" | jq -r '(.internal_results // []) | length')"
      EVOMAP_WEB="$(echo "$resp" | jq -r '(.web_results // []) | length')"
      if [[ "$EVOMAP_INTERNAL" -gt 0 || "$EVOMAP_WEB" -gt 0 || -n "$EVOMAP_SUMMARY" ]]; then
        EVOMAP_OK=true
      fi
    else
      EVOMAP_ERROR="EvoMap 返回空或非 JSON"
    fi
  else
    EVOMAP_ERROR="缺少 curl/jq，无法执行 EvoMap 查询"
  fi
else
  EVOMAP_ERROR="EvoMap 未启用"
fi

AGENT_REACH_USED=false
AGENT_REACH_OK=false
AGENT_REACH_ERROR=''
AGENT_REACH_CMD=''
AGENT_REACH_OUTPUT_FILE=''

if [[ "$EVOMAP_OK" != "true" ]]; then
  AGENT_REACH_USED=true
  if ! command -v mcporter >/dev/null 2>&1; then
    AGENT_REACH_ERROR="mcporter 不存在，无法使用 Agent-Reach 的 Exa 搜索能力"
  else
    if ! mcporter list exa --schema --json >/tmp/mcporter_exa_schema.json 2>/tmp/mcporter_exa_schema.err; then
      AGENT_REACH_ERROR="mcporter 未配置 exa 服务器，无法回退搜索"
    else
      exa_out_file="$ROOT_DIR/scripts/integrations/agent_reach/.state/mcporter_exa_last.txt"
      set +e
      mcporter call exa.web_search_exa query="$QUERY" numResults=5 >"$exa_out_file" 2>/tmp/mcporter_exa_search.err
      code1=$?
      set -e
      if [[ $code1 -eq 0 && -s "$exa_out_file" ]]; then
        AGENT_REACH_OK=true
        AGENT_REACH_OUTPUT_FILE="$exa_out_file"
        AGENT_REACH_CMD="mcporter call exa.web_search_exa"
      else
        AGENT_REACH_ERROR="mcporter Exa 查询失败"
      fi
    fi
  fi
fi

PROVIDER="none"
PASS=false
RESULT_PAYLOAD='{}'
RESULT_PAYLOAD_FILE=''
if [[ "$EVOMAP_OK" == "true" ]]; then
  PROVIDER="evomap"
  PASS=true
  RESULT_PAYLOAD="$EVOMAP_RESP"
elif [[ "$AGENT_REACH_OK" == "true" ]]; then
  PROVIDER="agent-reach"
  PASS=true
  RESULT_PAYLOAD_FILE="$AGENT_REACH_OUTPUT_FILE"
fi

python3 - "$OUT_FILE" "$QUERY" "$TASK_FILE" "$PROJECT" "$MODE" "$PASS" "$PROVIDER" "$EVOMAP_OK" "$EVOMAP_INTERNAL" "$EVOMAP_WEB" "$EVOMAP_SUMMARY" "$EVOMAP_ERROR" "$AGENT_REACH_USED" "$AGENT_REACH_OK" "$AGENT_REACH_CMD" "$AGENT_REACH_ERROR" "$RESULT_PAYLOAD" "$RESULT_PAYLOAD_FILE" <<'PY'
import json
import sys
from datetime import datetime, UTC
from pathlib import Path

(
  out_file, query, task_file, project, mode, passed, provider,
  evomap_ok, evomap_internal, evomap_web, evomap_summary, evomap_error,
  ar_used, ar_ok, ar_cmd, ar_error, result_payload, result_payload_file
) = sys.argv[1:]

def b(v):
  return str(v).lower() == 'true'

payload = {}
if result_payload_file:
  raw = ""
  try:
    raw = Path(result_payload_file).read_bytes().decode("utf-8", "replace")
    payload = json.loads(raw)
  except Exception:
    payload = {"raw": raw}
else:
  try:
    payload = json.loads(result_payload)
  except Exception:
    payload = {"raw": result_payload}

out = {
  "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
  "query": query,
  "task_file": task_file or None,
  "project": project or None,
  "mode": mode,
  "pass": b(passed),
  "provider": provider,
  "attempts": {
    "evomap": {
      "ok": b(evomap_ok),
      "internal_results": int(evomap_internal),
      "web_results": int(evomap_web),
      "summary": evomap_summary,
      "error": evomap_error or None,
    },
    "agent_reach": {
      "used": b(ar_used),
      "ok": b(ar_ok),
      "command": ar_cmd or None,
      "error": ar_error or None,
    }
  },
  "result": payload,
}

with open(out_file, 'w', encoding='utf-8') as f:
  json.dump(out, f, ensure_ascii=False, indent=2)

print(json.dumps(out, ensure_ascii=False, indent=2))
PY

echo "[web_search] 输出: $OUT_FILE"
