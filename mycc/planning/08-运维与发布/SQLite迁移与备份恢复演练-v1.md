# SQLite 迁移与备份恢复演练（v1）

> 目标：把“可恢复”能力提前标准化，避免后期高成本返工。

## 1. 迁移策略

1. 使用 `schema_migrations(version, applied_at)` 管版本。
2. 每次迁移包含：
- `up.sql`
- `down.sql`（回滚说明）
- 影响评估（是否破坏兼容）
3. 迁移执行必须幂等，可重复执行不报错。

## 2. 备份范围

1. 数据库：
- `memory/memory.db`
- `mycc/backend/data/*.db`

2. 文件产物：
- `tasks/<task_id>/runs/**`
- `manifest.json`

3. 配置与契约（建议）：
- `mycc/planning/02-契约/*`
- `skills-core/skill-registry.yaml`

## 3. 备份包格式（建议）

```text
backup-YYYYMMDD-HHMM/
  db/
    memory.db
    backend.db
  tasks/
    ...
  meta/
    checksum.sha256
    versions.json
```

`versions.json` 最小字段：
1. app_version
2. schema_version
3. backup_time

## 4. 恢复流程

1. 停写（只读模式或停机窗口）。
2. 恢复数据库文件。
3. 恢复 tasks 目录与 manifest。
4. 执行一致性检查：
- schema 版本检查
- 索引完整性检查
- manifest hash 校验
5. 执行可用性检查：
- 随机抽取 task run 做事件回放
- 核对 snapshot 是否可重建

## 5. 演练策略

1. 日备：每日自动备份。
2. 周检：每周随机恢复 1 个备份做完整流程演练。
3. 月演：每月一次全链路恢复演练（含事件回放）。

## 6. 验收标准

1. 恢复后 `GET /tasks/:id` 与 `GET /events?after` 可用。
2. 关键任务 run 可重放到终态。
3. 恢复失败时有清晰回滚步骤与错误报告。

---

版本：v1  
状态：运维演练规范
