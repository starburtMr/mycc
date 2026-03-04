# mycc 协作工作区

该工作区用于 Claude Code 与 Codex 的协同合作。
目标是：让规则可执行、状态可追踪、交接可复用。

## 核心规则

- `tasks/` 是任务状态唯一真源。
- 全局人格仅定义在 `0-System/about-me/persona.md`。
- `.claude/` 与 `.codex/` 为私有适配/配置区域。
- 项目级细节放在 `2-Projects/<project-name>/`。
- 交接记录必须写入项目 `handoff/`，不能只存在聊天里。
- 技术执行类任务默认先自主尝试 5 次，满足例外条件才允许提前中断。
- 会话上下文达到 60% 时必须进行阶段摘要压缩。
- Skill/MCP 默认最小加载，按项目白名单启用。

## 顶层结构

- `.claude/`：Claude 专用配置与适配层
- `.codex/`：Codex 专用配置与适配层
- `skills-core/`：共享技能核心内容
- `0-System/`：全局记忆系统
- `1-Inbox/`：想法收集箱
- `2-Projects/`：进行中的项目
- `3-Thinking/`：认知沉淀与思考记录
- `4-Assets/`：可复用资产
- `5-Archive/`：归档区
- `tasks/`：跨会话任务追踪（唯一真源）
- `memory/`：结构化长期记忆（SQLite）

## 运行策略（v2）

- `上下文压缩`：当上下文使用达到 60% 时，先做阶段摘要再继续执行。
- `尝试策略`：仅技术执行类任务强制 5 次尝试；若遇权限缺失、外部不可用、风险过高或成本超限，可提前中断。
- `模型路由`：按任务类型选模型，并记录 `route_reason`。
- `工具加载`：每个项目维护 `TOOLING_PROFILE.md`，未在白名单中的 Skill/MCP 默认禁用。
- `备份策略`：`memory/memory.db` 每日备份、每周全量快照、每月恢复演练。

## 会话协议

- `会话开始必读`：`0-System/about-me/SOUL.md`、`0-System/about-me/persona.md`、`tasks/index.md`、当前任务文件、对应项目 `context/`。
- `文本优先`：不要依赖“脑内记住”，重要信息必须写入文件（任务记录/状态/项目上下文）。
- `主会话优先写回`：直接协作会话中，优先更新任务与状态文件，避免只在聊天里留痕。
- `共享上下文降敏`：涉及对外或多人场景时，不回传无关私人上下文与敏感数据。

## 快速开始

1. 新建或选择任务文件（`tasks/active/*.md`）。
2. 运行会话开始检查。
3. 执行任务并持续更新任务字段。
4. 会话结束前完成交接字段与状态摘要回写。
5. 定期运行工作区巡检和 SQLite 巡检。

## 守护脚本

- 会话开始检查：
  - `bash scripts/guardrails/session_start.sh tasks/active/<task>.md`
- 会话结束检查：
  - `bash scripts/guardrails/session_end.sh tasks/active/<task>.md`
- 工作区巡检：
  - `bash scripts/guardrails/check_workspace.sh`
- SQLite 巡检：
  - `bash memory/scripts/run_memory_checks.sh`
