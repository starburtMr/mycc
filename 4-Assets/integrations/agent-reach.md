# Agent-Reach 接入手册（受限模式）

## 1. 启用

```bash
cp scripts/integrations/agent_reach/config.env.example scripts/integrations/agent_reach/config.local.sh
```

把 `config.local.sh` 中 `AGENT_REACH_ENABLED` 改为 `1`。

## 2. 安装

```bash
bash scripts/integrations/agent_reach/install.sh
```

## 3. 诊断

```bash
bash scripts/integrations/agent_reach/diagnose.sh
```

可选输出路径：

```bash
bash scripts/integrations/agent_reach/diagnose.sh 3-Thinking/sessions/<session_id>/agent-reach-diagnose.json
```

## 4. 更新

```bash
bash scripts/integrations/agent_reach/update.sh
```

## 5. 回滚

在 Agent-Reach 仓库目录查看备份 tag 并手动切回：

```bash
git -C .runtime/agent-reach/repo tag -l 'ar-backup-*'
git -C .runtime/agent-reach/repo checkout <tag>
```

## 禁止项

- 禁止脚本自动修改 `.claude/` 与 `.codex/` 配置。
- 禁止在未启用 `AGENT_REACH_NO_AGENT_CONFIG=1` 时执行安装和更新。


## 全量接入（官方 install）

```bash
bash scripts/integrations/agent_reach/full_install.sh auto
```

安全模式：

```bash
bash scripts/integrations/agent_reach/full_install.sh auto --safe
```

健康检查：

```bash
bash scripts/integrations/agent_reach/doctor.sh
```


## 系统调用手册

- 统一调用规范见：`4-Assets/integrations/agent-reach-system-playbook.md`
- 建议 Claude/Codex 在执行平台类任务前先读取该手册。
