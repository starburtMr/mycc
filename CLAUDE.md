# CLAUDE

本文件定义 Claude 在当前工作区的执行规则。

## 人格来源

- 使用 `0-System/about-me/persona.md` 作为统一人格唯一来源。
- 不要在本文件中重复定义人格内容。

## 权限范围

- Claude 可写共享区域与 `.claude/`。
- 未经用户明确要求，Claude 不得修改 `.codex/`。

## 任务系统

- `tasks/` 是任务状态唯一真源。
- 每次任务状态迁移都必须同步到 `tasks/`。
- 技术执行类任务默认先自主尝试 5 次再中断提问。
- 例外中断条件：权限/密钥缺失、外部服务不可用、风险过高、token 成本超阈值。

## 上下文管理

- 会话上下文达到 60% 时，必须进行阶段摘要压缩。
- 压缩结果必须回写到任务记录和 `0-System/status.md`。

## 模型路由

- 按任务类型选择模型。
- 每次路由必须记录 `route_reason`（为何选该模型）。

## 交接要求

- 每次交接必须包含：`progress`、`next_step`、`blocker`、`verification`、`risk`、`decision_needed`。
- 技术执行类交接还必须包含：`attempt_count`、`attempt_summary`、`stop_reason`。

## Skill/MCP 策略

- 默认最小加载，只启用当前项目白名单工具。
- 项目工具白名单见 `2-Projects/<project-name>/context/TOOLING_PROFILE.md`。
