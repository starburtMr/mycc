#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OUT_FILE="${1:-$ROOT_DIR/3-Thinking/sessions/obsidian-diagnose.json}"

enabled=false
[[ "${OBSIDIAN_ENABLED:-0}" == "1" ]] && enabled=true

cli_exists=false
if obs_cli_exists; then
  cli_exists=true
fi

cli_version=""
if [[ "$cli_exists" == "true" ]]; then
  set +e
  cli_version="$($OBSIDIAN_CLI_BIN --version 2>/dev/null | head -n1)"
  if [[ -z "$cli_version" ]]; then
    cli_version="$($OBSIDIAN_CLI_BIN version 2>/dev/null | head -n1)"
  fi
  set -e
fi

pass=false
if [[ "$enabled" == "true" && "$cli_exists" == "true" ]]; then
  pass=true
fi

repo_path="${OBSIDIAN_REPO_PATH:-/mnt/data/obsidian}"
repo_exists=false
remote_url=""
if [[ -d "$repo_path/.git" ]]; then
  repo_exists=true
  set +e
  remote_url="$(git -C "$repo_path" remote get-url origin 2>/dev/null)"
  set -e
fi

mkdir -p "$(dirname "$OUT_FILE")"

python3 - "$OUT_FILE" "$enabled" "$cli_exists" "$pass" "$OBSIDIAN_CLI_BIN" "$OBSIDIAN_VAULT_NAME" "$OBSIDIAN_DEFAULT_FOLDER" "$cli_version" "$repo_path" "$repo_exists" "$remote_url" "${OBSIDIAN_GIT_AUTO_PUSH:-1}" "${OBSIDIAN_GIT_BRANCH:-master}" "${OBSIDIAN_ROOT_FOLDER:-CC-AGENT-SPACE}" "${OBSIDIAN_DEFAULT_TYPE:-task}" "${OBSIDIAN_DEFAULT_STATUS:-active}" "${OBSIDIAN_ENFORCE_FRONTMATTER:-1}" "${OBSIDIAN_REQUIRE_CHINESE:-1}" <<'PY'
import json
import sys
from datetime import datetime, UTC

(
  out_file, enabled, cli_exists, passed,
  cli_bin, vault_name, default_folder, cli_version,
  repo_path, repo_exists, remote_url, auto_push, git_branch,
  root_folder, default_type, default_status, enforce_frontmatter, require_chinese
) = sys.argv[1:]

as_bool = lambda s: str(s).lower() == 'true'

obj = {
  "generated_at": datetime.now(UTC).replace(microsecond=0).isoformat().replace('+00:00','Z'),
  "integration": "obsidian",
  "pass": as_bool(passed),
  "checks": {
    "enabled": as_bool(enabled),
    "cli_exists": as_bool(cli_exists),
  },
  "config": {
    "cli_bin": cli_bin,
    "vault_name": vault_name or None,
    "default_folder": default_folder,
    "cli_version": cli_version or None,
    "repo_path": repo_path,
    "repo_exists": str(repo_exists).lower() == "true",
    "repo_remote": remote_url or None,
    "git_auto_push": str(auto_push) == "1",
    "git_branch": git_branch,
    "root_folder": root_folder,
    "default_type": default_type,
    "default_status": default_status,
    "enforce_frontmatter": str(enforce_frontmatter) == "1",
    "require_chinese": str(require_chinese) == "1",
  },
  "notes": [
    "建议先在 Obsidian 中开启 CLI，并确认 vault 可被 CLI 定位。"
  ]
}

with open(out_file, 'w', encoding='utf-8') as f:
  json.dump(obj, f, ensure_ascii=False, indent=2)

print(json.dumps(obj, ensure_ascii=False, indent=2))
PY

obs_log "诊断报告已写入: $OUT_FILE"
