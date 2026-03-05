---
name: obsidian-capture
description: 当需要把任务结论、决策、SOP 或会话沉淀写入 Obsidian 时使用。该技能会调用仓库脚本完成自动路由、Frontmatter 填充、校验与自动推送。
---

# obsidian-capture

## 触发条件

- 用户要求“写笔记到 Obsidian”“沉淀会话”“记录决策/SOP”。
- 任务完成后需要把结论落盘到 Obsidian 并同步远程。

## 前置检查

1. 先运行：

```bash
bash scripts/integrations/obsidian/diagnose.sh
```

2. 若 `pass=false`，先修复配置，不继续写入。

## 执行动作

1. 写单条笔记：

```bash
bash scripts/integrations/obsidian/capture_note.sh \
  --title "<标题>" \
  --type <task|adr|sop|profile|inbox|archive|retro> \
  --status <draft|active|done|archived> \
  --tags "cc,<tag2>" \
  --content "<正文>"
```

2. 写会话总结：

```bash
bash scripts/integrations/obsidian/push_session.sh 3-Thinking/sessions/<session_id>
```

## 路由规则

- `task/retro -> CC-AGENT-SPACE/10-Tasks`
- `adr -> CC-AGENT-SPACE/20-ADRs`
- `sop/knowledge/template -> CC-AGENT-SPACE/30-SOP`
- `profile -> CC-AGENT-SPACE/40-Profile`
- `inbox -> CC-AGENT-SPACE/00-Inbox`
- `archive -> CC-AGENT-SPACE/99-Archive`

## 质量闸门

推送前会自动执行：

```bash
bash scripts/integrations/obsidian/validate_notes.sh
```

必须满足：

1. Frontmatter 完整。
2. `type/status` 合法。
3. 默认含中文内容。

## 失败处理

1. 认证失败：检查 `ssh -T git@gitee.com`。
2. 校验失败：按错误提示补齐字段。
3. CLI 不可用：修正 `OBSIDIAN_CLI_BIN` 和 vault 配置。
