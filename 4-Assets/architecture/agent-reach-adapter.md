# Agent-Reach 受限接入架构

## 目标

- 复用 Agent-Reach 的工程化能力（install / diagnose / update）。
- 严格保持本系统边界：不自动改 `.claude/`、不覆盖既有人格与任务真源。

## 组件

- `scripts/integrations/agent_reach/install.sh`
- `scripts/integrations/agent_reach/diagnose.sh`
- `scripts/integrations/agent_reach/update.sh`
- `scripts/integrations/agent_reach/config.env.example`

## 模式

- 受限模式：`AGENT_REACH_NO_AGENT_CONFIG=1`，仅隔离安装，不改代理配置。
- 全量模式：执行官方 `agent-reach install --env=auto`，允许其安装 mcporter/exa 生态。
- 两种模式都保留结构化诊断输出，可被闭环评估使用。
- 更新前创建 git tag 备份，更新失败自动回退。

## 与现有系统关系

- 不替代 `session_start` 的 EvoMap 预检。
- 不替代 `skills-core` Router。
- 作为可选增强层，默认关闭（`AGENT_REACH_ENABLED=0`）。


## 全量接入现状

- 已验证 Agent-Reach 安装流程。
- 已通过 `mcporter + exa` 提供可用联网搜索回退能力。
- 统一入口仍由 `scripts/integrations/web_search.sh` 管理。
