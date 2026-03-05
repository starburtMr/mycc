#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/evomap/lib.sh"

TASK_FILE="${1:-}"
if [[ -z "$TASK_FILE" ]]; then
  echo "用法: bash scripts/evomap/preflight_search.sh tasks/active/<task>.md" >&2
  exit 1
fi

TASK_PATH="$ROOT_DIR/$TASK_FILE"
if [[ ! -f "$TASK_PATH" ]]; then
  echo "任务文件不存在: $TASK_PATH" >&2
  exit 1
fi

if [[ "$EVOMAP_ENABLED" != "1" ]]; then
  echo "[evomap] 已禁用，跳过预检"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "[evomap] 缺少 curl" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[evomap] 缺少 jq" >&2
  exit 2
fi

project="$(extract_task_field "$TASK_PATH" "project")"
if [[ -z "$project" ]]; then
  echo "[evomap] 任务缺少 project 字段" >&2
  exit 2
fi

title="$(extract_task_field "$TASK_PATH" "title")"
type="$(extract_task_field "$TASK_PATH" "type")"
goal="$(extract_task_field "$TASK_PATH" "goal")"
blocker="$(extract_task_field "$TASK_PATH" "blocker")"

query="$title; type=$type; goal=$goal; blocker=$blocker"
sender_id="$(ensure_query_sender_id)"

resp_file="$ROOT_DIR/2-Projects/$project/context/EVOMAP_LAST_SEARCH.json"
summary_file="$ROOT_DIR/2-Projects/$project/context/EVOMAP_EXPERIENCE.md"

req_payload="$(cat <<JSON
{
  \"sender_id\": \"$sender_id\",
  \"query\": $(jq -Rn --arg q "$query" '$q'),
  \"mode\": \"$EVOMAP_SEARCH_MODE\"
}
JSON
)"

resp="$(evomap_post_json "/a2a/skill/search" "$req_payload" || true)"

if [[ -z "$resp" ]]; then
  echo "[evomap] 检索失败：空响应或被只读策略拦截" >&2
  exit 3
fi

if ! echo "$resp" | jq . >/dev/null 2>&1; then
  echo "[evomap] 检索失败：非 JSON 响应" >&2
  exit 3
fi

echo "$resp" > "$resp_file"

ts="$(date '+%Y-%m-%d %H:%M:%S')"
summary="$(echo "$resp" | jq -r '.summary // ""')"
internal_count="$(echo "$resp" | jq -r '(.internal_results // []) | length')"
web_count="$(echo "$resp" | jq -r '(.web_results // []) | length')"

{
  echo "# EvoMap 经验检索"
  echo
  echo "- updated_at: $ts"
  echo "- sender_id: $sender_id"
  echo "- mode: $EVOMAP_SEARCH_MODE"
  echo "- query: $query"
  echo "- internal_results: $internal_count"
  echo "- web_results: $web_count"
  echo
  echo "## 摘要"
  if [[ -n "$summary" ]]; then
    echo "$summary"
  else
    echo "（无摘要，查看 JSON 结果）"
  fi
  echo
  echo "## 原始结果"
  echo "- 文件: 2-Projects/$project/context/EVOMAP_LAST_SEARCH.json"
} > "$summary_file"

echo "[evomap] 预检完成: $summary_file"
