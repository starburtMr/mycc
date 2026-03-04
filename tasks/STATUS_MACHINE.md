# 任务状态机（v1）

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

## 并发与归属

- 单任务同一时刻仅允许一个 owner（Claude/Codex/User）
- 并行工作应拆分为子任务并使用 `depends_on` 关联
