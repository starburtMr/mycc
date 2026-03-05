# 自动进化闭环（MVP）

## 目标

- 用最小代价建立 `PLAN -> EXECUTE -> EVAL -> REFLECT -> UPDATE` 闭环。
- 把每轮经验沉淀为可执行规则，而不是聊天记忆。

## 组件

- 编排入口：`scripts/loop/run_closed_loop.sh`
- 结构化评估：`scripts/loop/evaluate_session.sh`
- 会话产物：`3-Thinking/sessions/<session_id>/`
- 规则分层：`0-System/policy/{staging-rules,stable-rules,archive-rules}.md`
- 决策记录：`0-System/policy/decision-log.md`

## 运行方式

```bash
bash scripts/loop/run_closed_loop.sh tasks/active/<task>.md
```

可选：指定测试命令（作为硬评估）

```bash
TEST_CMD="pytest -q" bash scripts/loop/run_closed_loop.sh tasks/active/<task>.md
```

## 产物说明

每轮会在 `3-Thinking/sessions/<session_id>/` 生成：

- `input.md`：任务快照
- `plan.md`：计划占位
- `execute.md`：执行占位
- `eval.json`：结构化评估结果
- `reflection.md`：反思结论与候选规则
- `logs/`：巡检和测试日志

## 规则晋级策略

- 新规则先写入 `staging-rules.md`
- 连续 3 次会话验证通过后再写入 `stable-rules.md`
- 失败或替代规则写入 `archive-rules.md`
- 每次晋级/回滚动作必须写 `decision-log.md`
