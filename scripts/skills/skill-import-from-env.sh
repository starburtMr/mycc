#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IMPORTER="$ROOT_DIR/scripts/skills/skill-import.sh"

if [[ ! -x "$IMPORTER" ]]; then
  echo "缺少导入器: $IMPORTER"
  exit 2
fi

SKILL_ID="${SKILL_ID:-}"
if [[ -z "$SKILL_ID" ]]; then
  echo "缺少必填环境变量: SKILL_ID"
  exit 2
fi

SKILL_DISPLAY_NAME="${SKILL_DISPLAY_NAME:-$SKILL_ID}"
SKILL_CATEGORY="${SKILL_CATEGORY:-general}"
SKILL_MANAGER="${SKILL_MANAGER:-unknown}"
SKILL_REPO="${SKILL_REPO:-local}"
SKILL_VERSION="${SKILL_VERSION:-unknown}"

SKILL_ENTRY_SHARED="${SKILL_ENTRY_SHARED:-}"
SKILL_ENTRY_CODEX="${SKILL_ENTRY_CODEX:-}"
SKILL_ENTRY_CLAUDE="${SKILL_ENTRY_CLAUDE:-}"

# 未显式指定时自动推断平台支持
if [[ -n "${SKILL_SUPPORTS_CODEX:-}" ]]; then
  SKILL_SUPPORTS_CODEX="${SKILL_SUPPORTS_CODEX}"
elif [[ -n "$SKILL_ENTRY_CODEX" || -n "$SKILL_ENTRY_SHARED" ]]; then
  SKILL_SUPPORTS_CODEX="true"
else
  SKILL_SUPPORTS_CODEX="false"
fi

if [[ -n "${SKILL_SUPPORTS_CLAUDE:-}" ]]; then
  SKILL_SUPPORTS_CLAUDE="${SKILL_SUPPORTS_CLAUDE}"
elif [[ -n "$SKILL_ENTRY_CLAUDE" || -n "$SKILL_ENTRY_SHARED" ]]; then
  SKILL_SUPPORTS_CLAUDE="true"
else
  SKILL_SUPPORTS_CLAUDE="false"
fi

SKILL_OWNER="${SKILL_OWNER:-system}"
SKILL_TEST_STATUS="${SKILL_TEST_STATUS:-unverified}"
SKILL_NOTE="${SKILL_NOTE:-通过 post-install 自动导入}"
SKILL_LAST_VERIFIED_AT="${SKILL_LAST_VERIFIED_AT:-$(date +%F)}"
SKILL_REQUIRES_AUTH="${SKILL_REQUIRES_AUTH:-false}"
SKILL_READ_ONLY="${SKILL_READ_ONLY:-true}"
SKILL_DANGER_LEVEL="${SKILL_DANGER_LEVEL:-low}"
SKILL_HEALTH_CHECK_CMD="${SKILL_HEALTH_CHECK_CMD:-bash scripts/guardrails/check_skills_consistency.sh}"
SKILL_BLAST_RADIUS="${SKILL_BLAST_RADIUS:-readonly}"
SKILL_LIFECYCLE_STATUS="${SKILL_LIFECYCLE_STATUS:-draft}"
SKILL_DEFAULT_ENABLED="${SKILL_DEFAULT_ENABLED:-false}"

if [[ ! "$SKILL_ID" =~ ^[a-z0-9._-]+$ ]]; then
  echo "SKILL_ID 非法（仅允许 a-z0-9._-）: $SKILL_ID"
  exit 2
fi

for v in SKILL_SUPPORTS_CODEX SKILL_SUPPORTS_CLAUDE SKILL_REQUIRES_AUTH SKILL_READ_ONLY SKILL_DEFAULT_ENABLED; do
  val="${!v}"
  case "$val" in
    true|false) ;;
    *)
      echo "$v 非法（必须是 true/false）: $val"
      exit 2
      ;;
  esac
done

case "$SKILL_DANGER_LEVEL" in
  low|medium|high) ;;
  *)
    echo "SKILL_DANGER_LEVEL 非法（low/medium/high）: $SKILL_DANGER_LEVEL"
    exit 2
    ;;
esac
case "$SKILL_BLAST_RADIUS" in
  readonly|project_write|external_side_effect) ;;
  *)
    echo "SKILL_BLAST_RADIUS 非法: $SKILL_BLAST_RADIUS"
    exit 2
    ;;
esac
case "$SKILL_LIFECYCLE_STATUS" in
  draft|verified|deprecated|archived) ;;
  *)
    echo "SKILL_LIFECYCLE_STATUS 非法: $SKILL_LIFECYCLE_STATUS"
    exit 2
    ;;
esac
if [[ "$SKILL_LIFECYCLE_STATUS" != "verified" && "$SKILL_DEFAULT_ENABLED" == "true" ]]; then
  echo "仅 verified skill 允许 SKILL_DEFAULT_ENABLED=true"
  exit 2
fi

TMP_MANIFEST="$(mktemp)"
trap 'rm -f "$TMP_MANIFEST"' EXIT

cat > "$TMP_MANIFEST" <<YAML
skill_id: $SKILL_ID
display_name: $SKILL_DISPLAY_NAME
category: $SKILL_CATEGORY
source:
  manager: $SKILL_MANAGER
  repo: $SKILL_REPO
  version: "$SKILL_VERSION"
routing:
  entry_shared: "$SKILL_ENTRY_SHARED"
  entry_codex: "$SKILL_ENTRY_CODEX"
  entry_claude: "$SKILL_ENTRY_CLAUDE"
  supports_codex: $SKILL_SUPPORTS_CODEX
  supports_claude: $SKILL_SUPPORTS_CLAUDE
  default_enabled: $SKILL_DEFAULT_ENABLED
lifecycle_status: $SKILL_LIFECYCLE_STATUS
quality:
  owner: $SKILL_OWNER
  last_verified_at: "$SKILL_LAST_VERIFIED_AT"
  test_status: $SKILL_TEST_STATUS
governance:
  requires_auth: $SKILL_REQUIRES_AUTH
  read_only: $SKILL_READ_ONLY
  danger_level: $SKILL_DANGER_LEVEL
  blast_radius: $SKILL_BLAST_RADIUS
  health_check_cmd: $SKILL_HEALTH_CHECK_CMD
notes:
  - $SKILL_NOTE
YAML

bash "$IMPORTER" "$TMP_MANIFEST"
