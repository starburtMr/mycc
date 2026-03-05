# mycc 协作工作区

该工作区用于 Claude Code 与 Codex 的协同合作。
目标是：让规则可执行、状态可追踪、交接可复用。

## 核心规则

- `tasks/` 是任务状态唯一真源。
- 全局人格体系定义在 `0-System/about-me/SOUL.md`、`0-System/about-me/persona.md`、`0-System/about-me/user-profile.md`。
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

## 新增模板层（低风险接入）

- `4-Assets/prompts/`：核心提示词模板（`00-system/plan/implement/review/debug`）
- `3-Thinking/reflection/`：反思模板（`session-wrap/daily-reflection`）
- 说明：以上是模板与建议层，不是规则真源。规则真源仍在 `0-System/` 与 `tasks/`。

## 运行策略（v2）

- `上下文压缩`：当上下文使用达到 60% 时，先做阶段摘要再继续执行。
- `尝试策略`：仅技术执行类任务强制 5 次尝试；若遇权限缺失、外部不可用、风险过高或成本超限，可提前中断。
- `模型路由`：按任务类型选模型，并记录 `route_reason`。
- `工具加载`：每个项目维护 `TOOLING_PROFILE.md`，未在白名单中的 Skill/MCP 默认禁用。
- `备份策略`：`memory/memory.db` 每日备份、每周全量快照、每月恢复演练。

## 会话协议

- `会话开始必读`：`0-System/about-me/SOUL.md`、`0-System/about-me/persona.md`、`0-System/about-me/user-profile.md`、`tasks/index.md`、当前任务文件、对应项目 `context/`。
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
  - 说明：仅接受 `tasks/active/*.md` 路径，且任务必须填写合法 `project`。
- 会话结束检查：
  - `bash scripts/guardrails/session_end.sh tasks/active/<task>.md`
  - 说明：关键交接字段必须非空；技术任务额外校验 `attempt_*` 字段。
- 工作区巡检：
  - `bash scripts/guardrails/check_workspace.sh`
- SQLite 巡检：
  - `bash memory/scripts/run_memory_checks.sh`
- 一键自检：
  - `bash scripts/guardrails/self_check.sh`
  - 可选传任务：`bash scripts/guardrails/self_check.sh tasks/active/<task>.md`

## EvoMap 经验预检

- 系统已接入会话开始阶段的 EvoMap 自动检索：在 `session_start.sh` 中先检索经验，再进入执行。
- 当前为只读查询模式：不注册节点、不发心跳、不接任务。
- 这是硬闸门：会话开始前必须完成 EvoMap 检索，失败则阻断执行。
- 默认配置文件：`scripts/evomap/config.example.sh`
- 本地覆盖配置：`scripts/evomap/config.local.sh`（已加入 `.gitignore`）
- 严格模式：
  - `EVOMAP_STRICT=1`：检索失败阻断会话开始（默认）
- 只读开关：
  - `EVOMAP_READONLY=1`：仅允许知识查询接口
- 检索产物：
  - `2-Projects/<project>/context/EVOMAP_EXPERIENCE.md`
  - `2-Projects/<project>/context/EVOMAP_LAST_SEARCH.json`

## Skill Router（跨管理器标准化）

- 注册真源：`skills-core/skill-registry.yaml`
- 自动入口：`bash scripts/skills/post-install.sh`（推荐）
- 环境变量导入：`bash scripts/skills/skill-import-from-env.sh`
- 手工导入脚本：`bash scripts/skills/skill-import.sh <manifest.yaml>`
- 一致性校验：`bash scripts/guardrails/check_skills_consistency.sh`
- 工作区巡检已内置 skills 软检查（告警不阻断）
- Codex wrapper：`.codex/hooks/skill-post-install.sh`
- 详细说明见：`skills-core/README.md`

## 自动进化闭环（MVP）

- 闭环入口：`bash scripts/loop/run_closed_loop.sh tasks/active/<task>.md`
- 结构化评估：`bash scripts/loop/evaluate_session.sh <session_dir> tasks/active/<task>.md`
- 规则分层：`0-System/policy/staging-rules.md`、`stable-rules.md`、`archive-rules.md`
- 规则决策日志：`0-System/policy/decision-log.md`
- 架构说明：`4-Assets/architecture/evolution-loop-mvp.md`

## Agent-Reach 受限接入

- 适配目录：`scripts/integrations/agent_reach/`
- 安装：`bash scripts/integrations/agent_reach/install.sh`
- 诊断：`bash scripts/integrations/agent_reach/diagnose.sh`
- 更新：`bash scripts/integrations/agent_reach/update.sh`
- 默认关闭，且强制 `AGENT_REACH_NO_AGENT_CONFIG=1`（禁止改 `.claude/.codex`）
- 说明文档：`4-Assets/integrations/agent-reach.md`
- 系统调用手册：`4-Assets/integrations/agent-reach-system-playbook.md`

## 统一联网搜索（EvoMap 优先）

- 入口：`bash scripts/integrations/web_search.sh --query "<问题>" --task tasks/active/<task>.md`
- 路由：先 EvoMap，命中不足自动回退 `mcporter + Exa`（由 Agent-Reach 安装）
- 输出：结构化 JSON（项目上下文或 sessions 目录）
- 说明文档：`4-Assets/integrations/web-search.md`



## Agent-Reach 全量接入

- 官方安装封装：`bash scripts/integrations/agent_reach/full_install.sh auto`
- 安全模式：`bash scripts/integrations/agent_reach/full_install.sh auto --safe`
- 健康检查：`bash scripts/integrations/agent_reach/doctor.sh`

## CI 自动巡检

- 工作流：`.github/workflows/ci-guardrails.yml`
- 触发：`push(main)` 与 `pull_request`
- 执行内容：脚本语法检查、`check_workspace`、SQLite 巡检、`self_check`
- 目标：把会话规范从“人工执行”升级为“合并前自动闸门”

## 执行治理增强

- 能力契约检查：`bash scripts/guardrails/check_capability_contracts.sh`
- 写操作闸门：`bash scripts/guardrails/confirm_write_action.sh --action "<name>"`
  需要：`WRITE_ACTION_APPROVED=1` 与 `WRITE_ACTION_TOKEN=<token>`
- 闭环证据链：`run_closed_loop.sh` 会生成 `run_manifest.json` 与 `tool_calls.ndjson`

## Obsidian 绑定（CLI）

- 适配目录：`scripts/integrations/obsidian/`
- 诊断：`bash scripts/integrations/obsidian/diagnose.sh`
- 单条沉淀：`bash scripts/integrations/obsidian/capture_note.sh --title "..." --content "..."`
- 会话沉淀：`bash scripts/integrations/obsidian/push_session.sh 3-Thinking/sessions/<session_id>`
- 使用说明：`4-Assets/integrations/obsidian.md`

