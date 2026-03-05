# 统一联网搜索（EvoMap -> Agent-Reach）

## 目标

- 在执行任务前优先复用 EvoMap 经验。
- 当 EvoMap 命中不足时，自动回退 Agent-Reach。
- 输出统一结构化 JSON，进入闭环评估。

## 用法

```bash
bash scripts/integrations/web_search.sh --query "备份恢复系统 v30273：智能backup优化方案" --task tasks/active/<task>.md
```

可选参数：

- `--project <name>`：不提供 task 时手动指定项目
- `--out <path>`：指定输出 JSON 路径
- `--mode hybrid|internal|web`：EvoMap 查询模式

## 输出

默认输出：

- 有项目：`2-Projects/<project>/context/WEB_SEARCH_LAST.json`
- 无项目：`3-Thinking/sessions/web-search-<timestamp>.json`

## 结果字段

- `pass`: 是否命中成功
- `provider`: `evomap` / `agent-reach` / `none`
- `attempts.evomap`: 命中统计与错误信息
- `attempts.agent_reach`: 回退执行状态
- `result`: 原始返回（JSON）

## 约束

- 仍遵循 EvoMap 只读策略（不注册节点、不心跳、不接任务）。
- Agent-Reach 必须处于受限模式（禁止改 `.claude/.codex`）。
