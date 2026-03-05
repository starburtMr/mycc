# Skill 安装与治理规范 v1

> 目标：让本系统后续新增的所有 Skill（Claude/Codex 共用）都遵循同一约定，可注册、可校验、可回滚、可淘汰。

## 1. 统一约定（强制）

1. Skill 真源目录：`skills-core/skills/`。
2. 新建 Skill 必须先执行：`bash scripts/skills/init-skill.sh <skill-name>`。
3. 每个 Skill 必须包含：
   - `SKILL.md`
   - `agents/`
   - `scripts/`
   - `references/`
   - `assets/`
4. 子目录允许为空，但目录必须存在。
5. 禁止直接手工创建不合规目录结构。
6. 新 Skill 默认进入隔离流程：`quarantine -> promote -> register -> verified`。

## 2. 标准流程（强制）

1. 初始化目录骨架：

```bash
bash scripts/skills/init-skill.sh <skill-name>
```

2. 外部来源先入隔离区：

```bash
bash scripts/skills/quarantine-skill.sh <src_dir> <skill-name>
```

3. 结构通过后晋升主技能区：

```bash
bash scripts/skills/promote-skill.sh <skill-name>
```

4. 注册到系统路由：

```bash
bash scripts/skills/register-skill.sh \
  --skill-id <id> \
  --display-name "<name>" \
  --category engineering \
  --manager <manager-name> \
  --repo <repo-or-url> \
  --version <ver> \
  --entry-shared skills-core/skills/<skill-name>/SKILL.md \
  --supports-codex true \
  --supports-claude true \
  --lifecycle-status draft \
  --default-enabled false \
  --blast-radius project_write \
  --owner cc
```

5. 执行校验：

```bash
bash scripts/guardrails/check_skills_consistency.sh
bash scripts/guardrails/check_skill_structure.sh
bash scripts/guardrails/check_workspace.sh
```

## 3. 注册与路由

1. 注册真源唯一：`skills-core/skill-registry.yaml`。
2. 未进入 registry 的 Skill，系统视为不可调度。
3. Claude/Codex 路径可以不同，但路由标准一致，优先 `entry_shared`。
4. 仅 `verified` 且 `default_enabled=true` 的 skill 才允许默认路由。
5. 默认路由解析入口：`bash scripts/skills/resolve-active-skills.sh <codex|claude>`。

## 4. 元数据最小标准

每个 skill 在 registry 中必须有：

1. `skill_id`、`display_name`、`category`。
2. `source.manager/repo/version`。
3. `routing.entry_*`、`supports_*`、`default_enabled`。
4. `lifecycle_status`。
5. `quality.owner/last_verified_at/test_status`。
6. `governance.requires_auth/read_only/danger_level/blast_radius/health_check_cmd`。

## 5. 生命周期

1. `draft`：已创建，默认禁用路由。
2. `verified`：通过脚本校验与真实调用，可按需开启默认路由。
3. `deprecated`：不再推荐，强制禁用默认路由。
4. `archived`：下线，仅保留审计记录。

## 6. 回滚策略

1. 导入错误：重新执行 `register-skill.sh` 覆盖同 ID。
2. 路由异常：将 `default_enabled` 置为 `false` 临时下线。
3. 全量回退：回滚 `skill-registry.yaml` 到上一个稳定提交。

## 7. 月度治理

1. 月度 KPI：`bash scripts/loop/monthly_kpi.sh`。
2. 月度 Skill 评审：`bash scripts/skills/monthly_skill_review.sh`。
3. 低价值/高风险 skill 进入淘汰候选并降级 `default_enabled=false`。

## 8. 系统边界

1. 任务状态真源仍是 `tasks/`。
2. 关键路由决策要写 `route_reason`。
3. 未经用户明确要求，不改 `.claude/`。
