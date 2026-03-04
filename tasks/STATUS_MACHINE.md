# 任务状态机（v2）

## 状态集合

- todo
- doing
- review
- blocked
- done
- archived

## 合法迁移

- todo -> doing
- doing -> review
- doing -> blocked
- blocked -> doing
- review -> doing
- review -> done
- done -> archived

## 强制条件

- doing -> review: 必须填写 `verification`
- review -> done: 必须完成 `risk` 评估，且 `decision_needed=none` 或用户已拍板
- 任意 -> blocked: 必须填写 `blocker` 与解除条件
- 任意迁移: 必须更新 `next_step` 与 `owner`

## 技术任务尝试规则

- 技术执行类任务默认先自主尝试 5 次再中断提问。
- 例外中断条件：
  - 权限或密钥缺失
  - 外部服务不可用
  - 高风险操作需要用户确认
  - token 成本超过预算阈值
- 必填记录：`attempt_count`、`attempt_summary`、`stop_reason`

## 上下文压缩规则

- 会话上下文达到 60% 时，必须先做阶段摘要压缩。
- 压缩摘要必须回写到：
  - 当前任务记录
  - `0-System/status.md`

## 路由与并发

- 单任务同一时刻仅允许一个 owner（Claude/Codex/User）
- 并行工作应拆分为子任务并使用 `depends_on` 关联
- 每次路由必须记录 `route_model` 与 `route_reason`
