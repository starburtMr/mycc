# skills-core 使用说明

## 目标

- 统一管理 Skill 的注册与路由。
- 解决 Claude/Codex 技能目录不一致导致的漏加载问题。

## 关键文件

- `skills-core/skill-registry.yaml`：技能注册总表（唯一真源）。
- `skills-core/import-manifest-template.yaml`：导入清单模板。
- `skills-core/compat-matrix-template.yaml`：兼容矩阵模板。
- `scripts/skills/skill-import.sh`：导入脚本（新增或更新注册项）。
- `scripts/guardrails/check_skills_consistency.sh`：一致性校验脚本。

## 标准流程

1. 通过任意 skill 管理器安装技能到本地目录。
2. 复制模板并填写真实信息：
   - `cp skills-core/import-manifest-template.yaml /tmp/<skill>.yaml`
3. 执行导入：
   - `bash scripts/skills/skill-import.sh /tmp/<skill>.yaml`
4. 执行校验：
   - `bash scripts/guardrails/check_skills_consistency.sh`
5. 执行工作区巡检：
   - `bash scripts/guardrails/check_workspace.sh`

## 保证机制

- 每个技能必须有 `skill_id`，并写明 `supports_codex`/`supports_claude`。
- 若声明支持某平台，必须提供 `entry_<platform>` 或 `entry_shared`。
- 路径不存在、字段非法、重复 ID 会在一致性校验时报错。
- `check_workspace.sh` 已接入 skills 软检查，会输出告警。

## 失败处理

- 导入失败：修复 manifest 字段后重试。
- 一致性失败：修复路径或平台支持声明后重试。
- 若 PyYAML 缺失：先安装 `python3-yaml`（或等价包）。
