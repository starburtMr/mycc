# Agent-Reach Adapter

该目录为 mycc 的 Agent-Reach 受限适配层。

## 脚本

- `install.sh`: 受限安装（隔离目录 + 禁止改代理配置）
- `diagnose.sh`: 输出结构化健康报告 JSON
- `update.sh`: 带备份 tag 的更新与失败回退
- `full_install.sh`: 官方 `agent-reach install` 封装（全量接入）
- `doctor.sh`: 官方 `agent-reach doctor` 封装
- `lib.sh`: 公共配置与函数

## 配置

- 模板：`config.env.example`
- 本地覆盖：`config.local.sh`（需手动创建，已加入 `.gitignore`）
