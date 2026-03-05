# Obsidian 绑定手册（CLI）

## 目标

- 将系统会话结论、反思与知识沉淀写入 Obsidian。
- 使用 Obsidian CLI 作为统一入口。
- 统一资产标准：`Frontmatter + 自动路由 + push 前校验`。

## 1. 全流程（首次配置）

```bash
cp scripts/integrations/obsidian/config.env.example scripts/integrations/obsidian/config.local.sh
```

在 `config.local.sh` 填写并确认：

- `OBSIDIAN_ENABLED=1`
- `OBSIDIAN_CLI_BIN=/usr/local/bin/notesmd-cli`
- `OBSIDIAN_VAULT_NAME=obsidian`
- `OBSIDIAN_REPO_PATH=/mnt/data/obsidian`
- `OBSIDIAN_GIT_BRANCH=master`
- `OBSIDIAN_DEFAULT_FOLDER=CC-AGENT-SPACE/10-Tasks`

初始化目录结构：

```bash
bash scripts/integrations/obsidian/bootstrap.sh
```

配置远程为 SSH 并验证：

```bash
git -C /mnt/data/obsidian remote set-url origin git@gitee.com:lqy125130/obsidian.git
ssh -T git@gitee.com
```

## 2. 诊断

```bash
bash scripts/integrations/obsidian/diagnose.sh
```

## 3. 写入单条笔记

```bash
bash scripts/integrations/obsidian/capture_note.sh \
  --title "备份恢复方案评审" \
  --type task \
  --status active \
  --tags "cc,backup,review" \
  --content "今天的关键结论..."
```

说明：

- 不传 `--folder` 时会按 `--type` 自动路由：
  - `inbox -> CC-AGENT-SPACE/00-Inbox`
  - `task/retro -> CC-AGENT-SPACE/10-Tasks`
  - `adr -> CC-AGENT-SPACE/20-ADRs`
  - `sop/knowledge/template -> CC-AGENT-SPACE/30-SOP`
  - `profile -> CC-AGENT-SPACE/40-Profile`
  - `archive -> CC-AGENT-SPACE/99-Archive`
- 默认会自动补全 Frontmatter（`id/title/type/status/tags/source/owner/updated`）。

## 4. 追加到每日笔记

```bash
echo "- 今天新增规则：..." | bash scripts/integrations/obsidian/capture_note.sh --daily
```

## 5. 会话沉淀

```bash
bash scripts/integrations/obsidian/push_session.sh 3-Thinking/sessions/<session_id>
```

会写入：

- 默认文件夹：`CC-AGENT-SPACE/10-Tasks/Sessions`
- 内容：`run_id`、`eval` 摘要、`reflection`

## 6. Push 前校验（强制）

- 推送前会自动执行 `scripts/integrations/obsidian/validate_notes.sh`。
- 仅校验 `CC-AGENT-SPACE/` 下的 Markdown。
- 校验规则：
  - 必须存在 Frontmatter。
  - 必须包含字段：`id/title/type/status/tags/source/owner/updated`。
  - `type` 与 `status` 必须在允许枚举中。
  - 默认要求笔记包含中文内容（可在配置关闭）。

## 7. 推荐配置

- 默认目录：`CC-AGENT-SPACE`
- 每次任务收尾调用 `push_session.sh` 沉淀结果。
- 每周清理 `00-Inbox`，把可复用内容晋升到 `20-ADRs` 或 `30-SOP`。

## 8. 排障顺序（固定）

1. `bash scripts/integrations/obsidian/diagnose.sh`
2. `git -C /mnt/data/obsidian remote -v`
3. `ssh -T git@gitee.com`
4. `bash scripts/integrations/obsidian/capture_note.sh --title "诊断测试" --type task --content "测试"`
5. 若失败，先看 `capture_note.sh` 输出，再看 `validate_notes.sh` 报错字段。
