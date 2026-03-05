# post-install hooks

该目录用于放各类 skill 管理器的安装后适配脚本（wrapper）。

规则：

- 适配脚本只负责把管理器元信息映射为环境变量。
- 统一调用：`bash scripts/skills/post-install.sh`
- 必填环境变量：`SKILL_ID`

推荐最小环境变量：

- `SKILL_ID`
- `SKILL_DISPLAY_NAME`
- `SKILL_MANAGER`
- `SKILL_REPO`
- `SKILL_VERSION`
- `SKILL_ENTRY_SHARED` 或 `SKILL_ENTRY_CODEX` / `SKILL_ENTRY_CLAUDE`

示例：

```bash
export SKILL_ID="my_skill"
export SKILL_DISPLAY_NAME="My Skill"
export SKILL_MANAGER="acme-manager"
export SKILL_REPO="github.com/acme/my-skill"
export SKILL_VERSION="1.2.0"
export SKILL_ENTRY_CODEX=".codex/skills/my-skill/SKILL.md"
export SKILL_ENTRY_CLAUDE=".claude/skills/my-skill/SKILL.md"

bash scripts/skills/post-install.sh
```
