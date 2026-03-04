# SQLite 记忆系统说明（v1）

## 1. 目标

本系统用于 Claude 与 Codex 协同时的结构化长期记忆，要求：

- 可检索
- 可追溯
- 可审计
- 可演进

## 2. 设计原则

- `tasks/` 是任务状态唯一真源，SQLite 不替代任务状态机。
- Markdown（`0-System/`、`2-Projects/`）是叙述性记忆真源。
- SQLite 是结构化事实真源。
- 业务表可自由创建，但必须强制登记用途。
- 所有关键数据必须可追溯到 `task_id` 与 `source_path`。

## 3. 数据库位置

- 推荐路径：`memory/memory.db`
- 备份目录：`memory/backup/`

## 4. 固定系统表（不可省略）

### 4.1 `table_registry`

记录每张业务表的用途、归属与状态。

必填字段：

- `table_name`（主键）
- `purpose`（业务作用）
- `project`
- `owner_agent`（Claude/Codex/User）
- `source_task_id`
- `schema_version`
- `status`（active/deprecated）
- `created_at`
- `updated_at`

### 4.2 `column_registry`

记录字段语义、数据类型与敏感级别。

必填字段：

- `table_name`
- `column_name`
- `data_type`
- `meaning`
- `is_required`
- `pii_level`（none/low/high）
- `created_at`
- `updated_at`

### 4.3 `change_log`

记录所有 DDL 变更操作。

必填字段：

- `table_name`
- `action`（create_table/alter_table/deprecate_table/register_columns）
- `actor`（Claude/Codex/User）
- `task_id`
- `summary`
- `ddl_sql`
- `created_at`

## 5. 强制流程（建表/改表）

1. 创建或修改业务表。
2. 同一事务内写入 `table_registry`。
3. 同一事务内写入 `column_registry`。
4. 同一事务内写入 `change_log`。
5. 任一步失败，全部回滚。

## 6. 禁止项

- 禁止未登记用途的业务表长期存在。
- 禁止直接 `DROP TABLE`（改为 `status=deprecated`）。
- 禁止写入 token、secret、cookie、私钥。
- 禁止敏感字段却登记为 `pii_level=none`。

## 7. 并发与性能

- 建议启用 WAL。
- 高并发场景设置 `busy_timeout`。
- 索引仅用于高频过滤/关联字段，避免过度索引。

## 8. 巡检规则（必须定期执行）

- 未登记表巡检：业务表是否全部存在于 `table_registry`。
- 未登记字段巡检：关键字段是否全部存在于 `column_registry`。
- 过期表巡检：`deprecated` 表是否进入归档流程。

## 9. 备份与恢复

- 每日备份 `memory.db`。
- 设定保留周期（建议 30 天）。
- 每月至少一次恢复演练。
- 恢复后执行完整巡检。

## 10. 与现有目录协同

- 任务状态：`tasks/`
- 全局记忆：`0-System/`
- 项目记忆：`2-Projects/<project>/`
- 结构化记忆：`memory/memory.db`

## 11. 变更管理

任何 schema 变更必须附带：

- 变更目的
- 影响范围
- 回滚策略
- 对应 `task_id`

## 12. 版本信息

- 当前版本：v1
- 生效日期：YYYY-MM-DD
- 审核人：User

## 13. 快速开始

1. 初始化数据库

```bash
bash memory/scripts/init_memory_db.sh
```

2. 运行巡检

```bash
bash memory/scripts/run_memory_checks.sh
```

3. 示例 SQL

- `memory/sql/examples.sql` 提供建表示例、登记示例和查询示例。

4. 执行备份

```bash
bash memory/scripts/backup_memory_db.sh
```

- 建议通过定时任务每日执行该脚本。
- 每周可使用 `weekly_latest.db` 作为全量快照入口。
- 每月恢复演练建议：将备份文件复制到临时路径并运行巡检。
