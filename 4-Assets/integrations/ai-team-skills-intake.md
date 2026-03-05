# ai-team-skills 接入记录（隔离区）

## 来源

- repo: `ThendCN/ai-team-skills`
- url: `https://github.com/ThendCN/ai-team-skills`
- intake_date: 2026-03-05

## 已导入（隔离区）

导入位置：`skills-core/quarantine/`

1. `ai-team`
2. `codex-agent`
3. `gemini-agent`

## 导入方式

```bash
bash scripts/skills/import-repo-skills.sh <repo_dir> https://github.com/ThendCN/ai-team-skills
```

## 当前状态

- 状态：`quarantined`（未注册，不参与默认路由）
- 已补齐标准目录骨架：`agents/scripts/references/assets`

## 下一步（评审流程）

1. 人工审查每个 skill 的 `SKILL.md` 和 `scripts/*` 权限边界。
2. 按需改写为本系统规范（中文输出、route_reason、不改 `.claude/`）。
3. 使用 `promote-skill.sh` 晋升到 `skills-core/skills/`。
4. 使用 `register-skill.sh` 注册，初始 `lifecycle_status=draft`、`default_enabled=false`。
5. 验证通过后再改为 `verified`。
