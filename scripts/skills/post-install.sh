#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FROM_ENV="$ROOT_DIR/scripts/skills/skill-import-from-env.sh"
CHECKER="$ROOT_DIR/scripts/guardrails/check_skills_consistency.sh"

if [[ ! -x "$FROM_ENV" ]]; then
  echo "缺少脚本: $FROM_ENV"
  exit 2
fi

bash "$FROM_ENV"

# post-install 后立即做一致性校验，保证注册表可用
if [[ -x "$CHECKER" ]]; then
  bash "$CHECKER"
fi

echo "post-install 完成: ${SKILL_ID:-unknown}"
