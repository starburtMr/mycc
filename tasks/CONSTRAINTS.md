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
- 单任务同一时刻仅允许一个 owner：`Claude`、`Codex` 或 `User`。
