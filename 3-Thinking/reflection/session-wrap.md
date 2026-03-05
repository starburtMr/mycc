# session-wrap（结构化）

> 用途：每次会话结束后产出可执行反思，不写空话。
> 注意：本文件是建议层，规则真源在 `0-System/policy/`。

## 会话元信息

- date:
- session_id:
- task_id:
- project:
- hard_pass: true|false

## 事件与失效点（最多 3 条）

- trigger:
- failure_cause:
- evidence_file:

## 候选规则（最多 5 条，必须可执行）

- rule_statement: （必须包含触发条件 + 行动）
- verify_plan: （如何验证）
- owner:
- next_action: promote|revise|drop

## 更新建议（最多 3 条）

- target_file:
- patch_summary:
- reason:
