# Skill Router v1 设计

## 目标

- 统一管理 Claude 与 Codex 的技能来源，避免技能安装目录差异导致漏路由。
- 新安装技能必须可被自动发现，并进入统一注册表。
- 在不改 `.claude/` 的前提下，优先通过共享注册表驱动路由。

## 核心原则

- 单一真源：`skills-core/skill-registry.yaml`。
- 读写分层：安装器写 `skills-core/`，执行器只读注册表。
- 兼容优先：每个技能记录在 Claude/Codex 的可用状态与入口路径。
- 可审计：每次导入都必须带来源、版本、摘要、时间戳。

## 数据模型

- `skill_id`: 全局唯一标识，格式 `a-z0-9._-`。
- `display_name`: 展示名。
- `category`: 技能类别。
- `source`: 来源信息（manager/repo/version）。
- `routing`: 路由信息。
  - `entry_shared`: 共享规范入口（优先）。
  - `entry_codex`: Codex 入口（可为空）。
  - `entry_claude`: Claude 入口（可为空）。
  - `supports_codex`: bool。
  - `supports_claude`: bool。
- `quality`: 质量信息（owner/last_verified_at/test_status）。
- `notes`: 约束与已知问题。

## 导入流程

1. 安装器下载技能到各自管理器目录（外部流程）。
2. 安装后调用 `scripts/skills/post-install.sh`（推荐自动导入）。
3. `post-install` 内部通过 `skill-import-from-env.sh` 生成 manifest 并写入注册表。
4. 执行 `scripts/guardrails/check_skills_consistency.sh` 校验路径与字段。
5. 会话启动时通过 guardrails 软检查告警异常。

## 路由规则

- 同时支持 Claude 和 Codex：优先 `entry_shared`。
- 单平台支持：回退到对应平台入口。
- 双平台都缺入口：阻断执行并告警。

## 失败策略

- 导入失败：不改现有注册表，返回非 0。
- 校验失败：guardrails 产生告警，CI 可升级为阻断。

## 后续扩展

- 增加 `skill-lock.yaml`，记录解析后的稳定快照。
- 增加 `skills-core/hooks/post-install.d/`，接管不同管理器安装回调。
- 增加按项目的 `skill-policy.md`，限制可用技能集合。
