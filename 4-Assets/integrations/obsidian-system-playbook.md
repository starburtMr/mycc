# Obsidian 系统调用手册

> 目的：把 Obsidian 集成的“配置、调用、校验、推送”固化成系统标准，确保后续 Agent 可直接执行。

## 1. 当前基线（本仓库）

- Obsidian 仓库：`/mnt/data/obsidian`
- 远程地址：`git@gitee.com:lqy125130/obsidian.git`
- 默认分支：`master`
- 专属根目录：`CC-AGENT-SPACE`
- 默认写入目录：`CC-AGENT-SPACE/10-Tasks`
- CLI：`/usr/local/bin/notesmd-cli`

## 2. 一次性配置流程（首次）

1. 复制配置模板：

```bash
cp scripts/integrations/obsidian/config.env.example scripts/integrations/obsidian/config.local.sh
```

2. 修改本地配置（最少项）：

- `OBSIDIAN_ENABLED=1`
- `OBSIDIAN_CLI_BIN=/usr/local/bin/notesmd-cli`
- `OBSIDIAN_VAULT_NAME=obsidian`
- `OBSIDIAN_REPO_PATH=/mnt/data/obsidian`
- `OBSIDIAN_DEFAULT_FOLDER=CC-AGENT-SPACE/10-Tasks`
- `OBSIDIAN_GIT_AUTO_PUSH=1`

3. 初始化目录：

```bash
bash scripts/integrations/obsidian/bootstrap.sh
```

4. SSH 认证：

```bash
ssh -T git@gitee.com
```

5. 诊断：

```bash
bash scripts/integrations/obsidian/diagnose.sh
```

## 3. 调用入口（系统标准）

1. 单条笔记沉淀：

```bash
bash scripts/integrations/obsidian/capture_note.sh \
  --title "标题" \
  --type task \
  --status active \
  --tags "cc,task" \
  --content "正文"
```

2. 会话总结沉淀：

```bash
bash scripts/integrations/obsidian/push_session.sh 3-Thinking/sessions/<session_id>
```

3. 仅推送 Obsidian 仓库：

```bash
bash scripts/integrations/obsidian/push_git.sh "obsidian: 手动推送"
```

## 4. 路由规则（强制）

- `inbox -> CC-AGENT-SPACE/00-Inbox`
- `task/retro -> CC-AGENT-SPACE/10-Tasks`
- `adr -> CC-AGENT-SPACE/20-ADRs`
- `sop/knowledge/template -> CC-AGENT-SPACE/30-SOP`
- `profile -> CC-AGENT-SPACE/40-Profile`
- `archive -> CC-AGENT-SPACE/99-Archive`

## 5. 质量闸门（强制）

推送前自动执行 `validate_notes.sh`，规则如下：

1. 仅检查 `CC-AGENT-SPACE/` 下 Markdown。
2. 必须有 Frontmatter。
3. 必须包含字段：`id/title/type/status/tags/source/owner/updated`。
4. `type` 只能为：`inbox/task/adr/sop/profile/archive/knowledge/retro/template`。
5. `status` 只能为：`draft/active/done/archived`。
6. 默认要求内容含中文字符。

## 6. 与系统其他模块的关系

1. 任务真源仍是 `tasks/`，Obsidian 负责知识沉淀与检索。
2. 会话结束后建议顺序：更新 `tasks` -> 生成 `session` 目录 -> `push_session.sh`。
3. 关键决策需同步写一份 `adr` 类型笔记，便于后续检索。

## 7. 常见故障与处理

1. 报错 `could not read Username`：远程还在 HTTPS，切 SSH。
2. 报错 `笔记校验未通过`：补齐 Frontmatter 或修正 `type/status`。
3. 报错 `CLI 不可用`：确认 `OBSIDIAN_CLI_BIN` 路径和执行权限。
4. 没有自动推送：确认 `OBSIDIAN_GIT_AUTO_PUSH=1`。

## 8. 后续 Agent 的执行约束

1. 新建笔记默认必须使用 `capture_note.sh`，不要直接手写文件。
2. 重要会话结束必须调用 `push_session.sh`。
3. 不得写入密钥、Cookie、PII。
4. 若需要临时绕过自动推送，仅允许设置一次性变量：`OBSIDIAN_SKIP_AUTO_PUSH=1`。
