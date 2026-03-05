#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OBSIDIAN_REPO_PATH="${OBSIDIAN_REPO_PATH:-/mnt/data/obsidian}"

if [[ ! -d "$OBSIDIAN_REPO_PATH" ]]; then
  echo "Obsidian 仓库目录不存在: $OBSIDIAN_REPO_PATH" >&2
  exit 1
fi

dirs=(
  "$OBSIDIAN_FOLDER_INBOX"
  "$OBSIDIAN_FOLDER_TASKS"
  "$OBSIDIAN_FOLDER_ADRS"
  "$OBSIDIAN_FOLDER_SOP"
  "$OBSIDIAN_FOLDER_PROFILE"
  "$OBSIDIAN_FOLDER_ARCHIVE"
)

for d in "${dirs[@]}"; do
  mkdir -p "$OBSIDIAN_REPO_PATH/$d"
done

readme="$OBSIDIAN_REPO_PATH/$OBSIDIAN_ROOT_FOLDER/00-目录说明.md"
if [[ ! -f "$readme" ]]; then
  cat >"$readme" <<EOF
---
title: CC Agent 专属目录
owner: cc
language: zh-CN
tags: [cc,agent,workspace]
updated: $(date +%F)
---

# CC Agent 专属目录

用途：存放 Claude/Codex 协作的任务笔记、决策记录、SOP 与复盘。

目录说明：
- 00-Inbox：临时输入，待分流
- 10-Tasks：任务过程与结果
- 20-ADRs：关键决策记录
- 30-SOP：可复用方法
- 40-Profile：偏好与规则
- 99-Archive：归档
EOF
fi

obs_log "初始化完成: $OBSIDIAN_REPO_PATH/$OBSIDIAN_ROOT_FOLDER"
