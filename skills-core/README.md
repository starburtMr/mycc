# skills-core 使用说明

## 目标

- 统一管理 Skill 的注册与路由。
- 解决 Claude/Codex 技能目录不一致导致的漏加载问题。

## 关键文件

- `skills-core/skill-registry.yaml`：技能注册总表（唯一真源）。
- `skills-core/skills/`：共享 skill 包（建议包含 `SKILL.md`）。
- `skills-core/templates/skill-package/`：skill 与 manifest 模板。
- `scripts/skills/init-skill.sh`：初始化标准 skill 目录（强制目录骨架）。
- `scripts/skills/quarantine-skill.sh`：将外部 skill 放入隔离区。
- `scripts/skills/promote-skill.sh`：将隔离区 skill 晋升到主技能区。
- `skills-core/import-manifest-template.yaml`：导入清单模板。
- `skills-core/compat-matrix-template.yaml`：兼容矩阵模板。
- `scripts/skills/skill-import.sh`：导入脚本（新增或更新注册项）。
- `scripts/skills/register-skill.sh`：统一注册入口（推荐）。
- `scripts/skills/resolve-active-skills.sh`：解析默认可路由技能。
- `scripts/skills/route-skill.sh`：按 query 执行默认路由匹配。
- `scripts/skills/auto-downgrade.sh`：按治理规则自动降级 skill。
- `scripts/guardrails/check_skills_consistency.sh`：一致性校验脚本。
- `scripts/guardrails/check_skill_structure.sh`：目录结构强校验脚本。

## 标准流程

1. 新建 skill 时先初始化目录骨架（强制）：
   - `bash scripts/skills/init-skill.sh <skill-name>`
2. 外部来源先进入隔离区：
   - `bash scripts/skills/quarantine-skill.sh <src_dir> <skill-name>`
3. 结构通过后晋升：
   - `bash scripts/skills/promote-skill.sh <skill-name>`
4. 安装后调用统一入口（推荐）：
   - `bash scripts/skills/post-install.sh`（通过环境变量自动导入）
   - 或 `bash scripts/skills/register-skill.sh ...`（显式参数导入）
5. 或者手工导入（兜底）：
   - `cp skills-core/import-manifest-template.yaml /tmp/<skill>.yaml`
   - `bash scripts/skills/skill-import.sh /tmp/<skill>.yaml`
6. 执行一致性校验：
   - `bash scripts/guardrails/check_skills_consistency.sh`
   - `bash scripts/guardrails/check_skill_structure.sh`
7. 执行工作区巡检：
   - `bash scripts/guardrails/check_workspace.sh`

## 路由与降级示例

```bash
bash scripts/skills/route-skill.sh --platform codex --query "写入 Obsidian 决策笔记"
bash scripts/skills/auto-downgrade.sh --dry-run
```

## 自动导入最小示例

```bash
export SKILL_ID="my_skill"
export SKILL_DISPLAY_NAME="My Skill"
export SKILL_MANAGER="your-manager"
export SKILL_REPO="github.com/org/my-skill"
export SKILL_VERSION="1.0.0"
export SKILL_ENTRY_CODEX=".codex/skills/my-skill/SKILL.md"
export SKILL_ENTRY_CLAUDE=".claude/skills/my-skill/SKILL.md"

bash scripts/skills/post-install.sh
```

## 显式注册示例（推荐给本系统）

```bash
bash scripts/skills/register-skill.sh \
  --skill-id obsidian_capture \
  --display-name "Obsidian Capture" \
  --category productivity \
  --manager manual \
  --repo local/mycc \
  --version 1.0.0 \
  --entry-shared skills-core/skills/obsidian-capture/SKILL.md \
  --lifecycle-status draft \
  --default-enabled false \
  --blast-radius project_write \
  --supports-codex true \
  --supports-claude true \
  --owner cc
```

## 保证机制

- 每个 skill 目录必须存在：`agents/`、`scripts/`、`references/`、`assets/`（可为空）。
- 每个技能必须有 `skill_id`，并写明 `supports_codex`/`supports_claude`。
- 非 `verified` skill 必须 `default_enabled=false`。
- 每个 skill 必须声明 `governance.blast_radius`。
- 若声明支持某平台，必须提供 `entry_<platform>` 或 `entry_shared`。
- 路径不存在、字段非法、重复 ID 会在一致性校验时报错。
- `check_workspace.sh` 已接入 skills 软检查，会输出告警。
- `.codex/hooks/skill-post-install.sh` 可作为 Codex 侧标准 wrapper 调用入口。
- 统一治理规范见：`4-Assets/architecture/skill-governance-v1.md`

## 失败处理

- 导入失败：修复 manifest 字段后重试。
- 一致性失败：修复路径或平台支持声明后重试。
- 若 PyYAML 缺失：先安装 `python3-yaml`（或等价包）。
