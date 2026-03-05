#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ "$AGENT_REACH_ENABLED" != "1" ]]; then
  ar_log "适配层未启用。请设置 AGENT_REACH_ENABLED=1"
  exit 1
fi
if [[ "$AGENT_REACH_NO_AGENT_CONFIG" != "1" ]]; then
  ar_log "拒绝执行：必须启用 AGENT_REACH_NO_AGENT_CONFIG=1"
  exit 1
fi

REPO_DIR="$(ar_repo_dir)"
VENV_PIP="$(ar_venv_pip)"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  ar_log "仓库不存在，请先执行 install.sh"
  exit 1
fi

if ! git -C "$REPO_DIR" diff --quiet || ! git -C "$REPO_DIR" diff --cached --quiet; then
  ar_log "仓库存在未提交改动，拒绝更新。请先清理本地改动。"
  exit 1
fi

OLD_COMMIT="$(git -C "$REPO_DIR" rev-parse HEAD)"
BACKUP_TAG="ar-backup-$(date +%Y%m%dT%H%M%S)"

ar_log "创建更新前标签: $BACKUP_TAG"
git -C "$REPO_DIR" tag "$BACKUP_TAG" "$OLD_COMMIT"

if ! git -C "$REPO_DIR" fetch --depth 1 origin "$AGENT_REACH_REF"; then
  ar_log "拉取失败，保持当前版本"
  exit 1
fi

if ! git -C "$REPO_DIR" merge --ff-only FETCH_HEAD; then
  ar_log "更新失败，回滚到旧版本"
  git -C "$REPO_DIR" checkout -q "$OLD_COMMIT"
  exit 1
fi

if ! "$VENV_PIP" install -e "$REPO_DIR"; then
  ar_log "依赖安装失败，回滚"
  git -C "$REPO_DIR" checkout -q "$OLD_COMMIT"
  "$VENV_PIP" install -e "$REPO_DIR" >/dev/null || true
  exit 1
fi

NEW_COMMIT="$(git -C "$REPO_DIR" rev-parse --short HEAD)"
python3 - "$STATE_DIR/update_state.json" "$OLD_COMMIT" "$NEW_COMMIT" "$BACKUP_TAG" <<'PY'
import json
import sys
from datetime import datetime, UTC

path, old_c, new_c, tag = sys.argv[1:]
data = {
    "updated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "from": old_c,
    "to": new_c,
    "backup_tag": tag,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

ar_log "更新完成: $OLD_COMMIT -> $NEW_COMMIT"
