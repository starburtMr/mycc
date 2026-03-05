#!/usr/bin/env bash
set -euo pipefail

ACTION=""
REASON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)
      ACTION="${2:-}"
      shift 2
      ;;
    --reason)
      REASON="${2:-}"
      shift 2
      ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$ACTION" ]]; then
  echo "用法: bash scripts/guardrails/confirm_write_action.sh --action <name> [--reason <text>]" >&2
  exit 2
fi

if [[ "${WRITE_ACTION_APPROVED:-0}" != "1" ]]; then
  echo "[write_gate] 拒绝执行写操作: $ACTION（缺少 WRITE_ACTION_APPROVED=1）" >&2
  exit 1
fi

TOKEN="${WRITE_ACTION_TOKEN:-}"
if [[ ! "$TOKEN" =~ ^[A-Za-z0-9._-]{8,}$ ]]; then
  echo "[write_gate] 拒绝执行写操作: $ACTION（WRITE_ACTION_TOKEN 非法）" >&2
  exit 1
fi

echo "[write_gate] 已授权写操作: $ACTION"
if [[ -n "$REASON" ]]; then
  echo "[write_gate] reason: $REASON"
fi
