# tasks 约束

- `tasks/` 是任务状态唯一真源。
- 允许状态值：`todo`、`doing`、`review`、`blocked`、`done`、`archived`。
- 任意交接必须包含字段：
  - `progress`
  - `next_step`
  - `blocker`
  - `verification`
  - `risk`
  - `decision_needed`
- 技术执行类任务还必须记录：
  - `attempt_count`
  - `attempt_summary`
  - `stop_reason`
- 单任务同一时刻仅允许一个 owner：`Claude`、`Codex` 或 `User`。
- 上下文达到 60% 必须触发摘要压缩，并在任务记录中写入压缩结果。
- 每次模型路由必须记录：`route_model`、`route_reason`。
