# skills-core 约束

- 这里是共享技能内容的唯一来源。
- 仅放平台无关的方法、模板与规范。
- 平台适配信息放在 `.claude/skills/` 与 `.codex/skills/`。
- 新建 Skill 必须通过 `scripts/skills/init-skill.sh` 创建目录骨架。
- 每个 Skill 必须包含：`SKILL.md`、`agents/`、`scripts/`、`references/`、`assets/`（子目录可为空）。
- 目录结构强校验：`bash scripts/guardrails/check_skill_structure.sh`。
