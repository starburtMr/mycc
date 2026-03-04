#!/usr/bin/env bash

# 读取 markdown 字段值，格式: - key: value
read_field() {
  local file="$1"
  local key="$2"
  sed -n "s/^- ${key}:[[:space:]]*//p" "$file" | head -n1 | xargs
}

is_valid_project_name() {
  local project="$1"
  [[ "$project" =~ ^[a-zA-Z0-9._-]+$ ]]
}

is_technical_task_type() {
  local task_type
  task_type="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$task_type" =~ ^(feature|bug|refactor|chore|backend|frontend|api|db|infra|test)$ ]]
}

is_placeholder_value() {
  local v
  v="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$v" =~ ^(tbd|todo|none|n/a|na|pending|待定|暂无)$ ]]
}
