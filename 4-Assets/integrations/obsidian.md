# Obsidian 绑定手册（CLI）

## 目标

- 将系统会话结论、反思与知识沉淀写入 Obsidian。
- 使用 Obsidian CLI 作为统一入口。

## 1. 启用

```bash
cp scripts/integrations/obsidian/config.env.example scripts/integrations/obsidian/config.local.sh
```

将 `config.local.sh` 里的 `OBSIDIAN_ENABLED` 改为 `1`。

## 2. 诊断

```bash
bash scripts/integrations/obsidian/diagnose.sh
```

## 3. 写入单条笔记

```bash
bash scripts/integrations/obsidian/capture_note.sh \
  --title "AI 复盘" \
  --folder "AI/Inbox" \
  --content "今天的关键结论..."
```

## 4. 追加到每日笔记

```bash
echo "- 今天新增规则：..." | bash scripts/integrations/obsidian/capture_note.sh --daily
```

## 5. 会话沉淀

```bash
bash scripts/integrations/obsidian/push_session.sh 3-Thinking/sessions/<session_id>
```

会写入：

- 默认文件夹：`$OBSIDIAN_DEFAULT_FOLDER/Sessions`
- 内容：`run_id`、`eval` 摘要、`reflection`

## 建议

- 在 Obsidian 里建固定目录：`AI/Inbox`、`AI/Sessions`、`AI/Rules`
- 每次任务收尾时调用 `push_session.sh`，形成稳定知识沉淀链。
