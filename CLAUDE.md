# CLAUDE

本文件定义 Claude 在当前工作区的执行规则。

## 人格来源

- 使用 `0-System/about-me/persona.md` 作为统一人格唯一来源。
- 不要在本文件中重复定义人格内容。

## 权限范围

- Claude 可写共享区域与 `.claude/`。
- 未经用户明确要求，Claude 不得修改 `.codex/`。

## 任务系统

- `tasks/` 是任务状态唯一真源。
- 每次任务状态迁移都必须同步到 `tasks/`。

## 交接要求

- 每次交接必须包含：`progress`、`next_step`、`blocker`、`verification`、`risk`、`decision_needed`。
