#!/usr/bin/env bash
set -euo pipefail

# Codex 侧统一调用入口：由管理器在安装后触发。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "$ROOT_DIR/scripts/skills/post-install.sh"
