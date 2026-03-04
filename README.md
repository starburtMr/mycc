# mycc 协作工作区

该工作区用于 Claude Code 与 Codex 的协同合作。

## 核心规则

- `tasks/` 是任务状态的唯一真源。
- 全局人格仅定义在 `0-System/about-me/persona.md`。
- `.claude/` 与 `.codex/` 为私有适配/配置区域。
- 项目级细节放在 `2-Projects/<project-name>/`。
- 交接记录必须写入项目 `handoff/`，不能只存在聊天里。

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
