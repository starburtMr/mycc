#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMPORTER="$ROOT_DIR/scripts/skills/skill-import.sh"
CHECKER="$ROOT_DIR/scripts/guardrails/check_skills_consistency.sh"

SKILL_ID=""
DISPLAY_NAME=""
CATEGORY="general"
MANAGER="manual"
REPO="local"
VERSION="unknown"
ENTRY_SHARED=""
ENTRY_CODEX=""
ENTRY_CLAUDE=""
SUPPORTS_CODEX="true"
SUPPORTS_CLAUDE="true"
OWNER="system"
TEST_STATUS="unverified"
NOTE="通过 register-skill.sh 导入"
REQUIRES_AUTH="false"
READ_ONLY="true"
DANGER_LEVEL="low"
HEALTH_CHECK_CMD="bash scripts/guardrails/check_skills_consistency.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill-id) SKILL_ID="${2:-}"; shift 2 ;;
    --display-name) DISPLAY_NAME="${2:-}"; shift 2 ;;
    --category) CATEGORY="${2:-}"; shift 2 ;;
    --manager) MANAGER="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --entry-shared) ENTRY_SHARED="${2:-}"; shift 2 ;;
    --entry-codex) ENTRY_CODEX="${2:-}"; shift 2 ;;
    --entry-claude) ENTRY_CLAUDE="${2:-}"; shift 2 ;;
    --supports-codex) SUPPORTS_CODEX="${2:-}"; shift 2 ;;
    --supports-claude) SUPPORTS_CLAUDE="${2:-}"; shift 2 ;;
    --owner) OWNER="${2:-}"; shift 2 ;;
    --test-status) TEST_STATUS="${2:-}"; shift 2 ;;
    --note) NOTE="${2:-}"; shift 2 ;;
    --requires-auth) REQUIRES_AUTH="${2:-}"; shift 2 ;;
    --read-only) READ_ONLY="${2:-}"; shift 2 ;;
    --danger-level) DANGER_LEVEL="${2:-}"; shift 2 ;;
    --health-check-cmd) HEALTH_CHECK_CMD="${2:-}"; shift 2 ;;
    *)
      echo "未知参数: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SKILL_ID" ]]; then
  echo "缺少参数 --skill-id" >&2
  exit 2
fi
if [[ -z "$DISPLAY_NAME" ]]; then
  DISPLAY_NAME="$SKILL_ID"
fi

for b in SUPPORTS_CODEX SUPPORTS_CLAUDE REQUIRES_AUTH READ_ONLY; do
  case "${!b}" in
    true|false) ;;
    *)
      echo "$b 非法（必须 true/false）: ${!b}" >&2
      exit 2
      ;;
  esac
done

case "$DANGER_LEVEL" in
  low|medium|high) ;;
  *)
    echo "DANGER_LEVEL 非法（low/medium/high）: $DANGER_LEVEL" >&2
    exit 2
    ;;
esac

TMP_MANIFEST="$(mktemp)"
trap 'rm -f "$TMP_MANIFEST"' EXIT

cat > "$TMP_MANIFEST" <<YAML
skill_id: $SKILL_ID
display_name: $DISPLAY_NAME
category: $CATEGORY
source:
  manager: $MANAGER
  repo: $REPO
  version: "$VERSION"
routing:
  entry_shared: "$ENTRY_SHARED"
  entry_codex: "$ENTRY_CODEX"
  entry_claude: "$ENTRY_CLAUDE"
  supports_codex: $SUPPORTS_CODEX
  supports_claude: $SUPPORTS_CLAUDE
quality:
  owner: $OWNER
  last_verified_at: "$(date +%F)"
  test_status: $TEST_STATUS
governance:
  requires_auth: $REQUIRES_AUTH
  read_only: $READ_ONLY
  danger_level: $DANGER_LEVEL
  health_check_cmd: $HEALTH_CHECK_CMD
notes:
  - $NOTE
YAML

bash "$IMPORTER" "$TMP_MANIFEST"
bash "$CHECKER"
echo "注册完成: $SKILL_ID"
