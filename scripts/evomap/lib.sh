#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CFG_EXAMPLE="$ROOT_DIR/scripts/evomap/config.example.sh"
CFG_LOCAL="$ROOT_DIR/scripts/evomap/config.local.sh"
STATE_DIR="$ROOT_DIR/scripts/evomap/.state"
NODE_ID_FILE="$STATE_DIR/node_id"

source "$CFG_EXAMPLE"
if [[ -f "$CFG_LOCAL" ]]; then
  source "$CFG_LOCAL"
fi

mkdir -p "$STATE_DIR"

random_hex() {
  local n="${1:-8}"
  od -An -N"$((n/2))" -tx1 /dev/urandom | tr -d ' \n'
}

now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

new_message_id() {
  echo "msg_$(date +%s)_$(random_hex 8)"
}

ensure_query_sender_id() {
  if [[ -f "$NODE_ID_FILE" ]]; then
    cat "$NODE_ID_FILE"
    return 0
  fi
  local node_id="query_$(random_hex 16)"
  echo "$node_id" > "$NODE_ID_FILE"
  cat "$NODE_ID_FILE"
}

assert_readonly_path() {
  local path="$1"
  # 只读模式下，仅允许知识查询接口
  if [[ "${EVOMAP_READONLY:-1}" == "1" ]]; then
    case "$path" in
      "/a2a/skill/search"|"/skill.md")
        return 0
        ;;
      *)
        echo "[evomap] 只读模式禁止访问接口: $path" >&2
        return 1
        ;;
    esac
  fi
  return 0
}

evomap_post_json() {
  local path="$1"
  local payload="$2"
  if ! assert_readonly_path "$path"; then
    return 1
  fi
  curl -sS -X POST "$EVOMAP_HUB_URL$path" \
    -H 'Content-Type: application/json' \
    -d "$payload"
}

evomap_get_text() {
  local path="$1"
  if ! assert_readonly_path "$path"; then
    return 1
  fi
  curl -sS "$EVOMAP_HUB_URL$path"
}

extract_task_field() {
  local task_file="$1"
  local key="$2"
  sed -n "s/^- ${key}:[[:space:]]*//p" "$task_file" | head -n1 | xargs
}
