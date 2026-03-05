# Agent-Reach 受限接入架构

## 目标

- 复用 Agent-Reach 的工程化能力（install / diagnose / update）。
- 严格保持本系统边界：不自动改 `.claude/`、不覆盖既有人格与任务真源。

## 组件

- `scripts/integrations/agent_reach/install.sh`
- `scripts/integrations/agent_reach/diagnose.sh`
- `scripts/integrations/agent_reach/update.sh`
- `scripts/integrations/agent_reach/config.env.example`

## 受限策略

- 必须开启 `AGENT_REACH_NO_AGENT_CONFIG=1`。
- 仅在隔离目录 `.runtime/agent-reach` 内安装。
- 诊断输出结构化 JSON，可被闭环评估使用。
- 更新前创建 git tag 备份，更新失败自动回退。

## 与现有系统关系

- 不替代 `session_start` 的 EvoMap 预检。
- 不替代 `skills-core` Router。
- 作为可选增强层，默认关闭（`AGENT_REACH_ENABLED=0`）。
