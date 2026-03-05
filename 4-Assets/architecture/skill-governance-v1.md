# Skill 安装与治理规范 v1

> 目标：让 Claude/Codex 在同一套技能体系下稳定协作，避免“装了 skill 但没进路由”。

## 1. 设计原则

1. 注册真源唯一：`skills-core/skill-registry.yaml`。
2. 安装与注册解耦：安装由管理器执行，注册由本系统脚本执行。
3. 先注册再使用：未进入 registry 的 skill，系统视为不可调度。
4. 每次导入后必须跑一致性检查：`check_skills_consistency.sh`。
5. 项目内调用必须受 `TOOLING_PROFILE.md` 白名单约束。

## 2. 标准安装流程（强制）

1. 用任意管理器安装 skill 到本地目录。
2. 使用统一入口注册：

```bash
bash scripts/skills/register-skill.sh \
  --skill-id <id> \
  --display-name "<name>" \
  --category engineering \
  --manager <manager-name> \
  --repo <repo-or-url> \
  --version <ver> \
  --entry-shared <path-to-SKILL.md> \
  --supports-codex true \
  --supports-claude true \
  --owner cc
```

3. 执行一致性检查：

```bash
bash scripts/guardrails/check_skills_consistency.sh
```

4. 执行工作区巡检：

```bash
bash scripts/guardrails/check_workspace.sh
```

## 3. 最小元数据标准

每个 skill 在 registry 中必须包含：

1. `skill_id`：小写字母/数字/`._-`。
2. `display_name`、`category`、`source`。
3. `routing`：`entry_shared/entry_codex/entry_claude` 与平台支持布尔值。
4. `quality`：`owner/last_verified_at/test_status`。
5. `governance`：`requires_auth/read_only/danger_level/health_check_cmd`。

## 4. 平台差异处理

1. Claude/Codex 的技能目录可以不同，但 registry 要统一。
2. 优先使用 `entry_shared` 指向仓库内共享 skill 文档。
3. 仅当平台需要额外适配时，再写 `entry_codex` 或 `entry_claude`。

## 5. 生命周期

1. `draft`：刚注册，未验证。
2. `verified`：通过 `health_check_cmd` 与真实调用验证。
3. `deprecated`：不再推荐，禁止默认路由。
4. `archived`：完全下线，仅保留审计记录。

## 6. 回滚策略

1. 导入错误：重新执行 `register-skill.sh` 覆盖同 ID 条目。
2. 路由异常：将 `supports_*` 置为 `false`，临时下线。
3. 功能回退：回滚 registry 到上一个稳定提交。

## 7. 与系统规则对齐

1. 不得修改 `.claude/`（除用户明确要求）。
2. 任务状态仍以 `tasks/` 为真源。
3. 关键路由决策必须写 `route_reason`。
