-- 示例1：创建业务表（示例）
CREATE TABLE IF NOT EXISTS api_endpoints (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT NOT NULL,
  method TEXT NOT NULL,
  requires_auth INTEGER NOT NULL CHECK (requires_auth IN (0,1)),
  rate_limit TEXT,
  source_path TEXT,
  source_ref TEXT,
  task_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- 示例2：登记业务表
INSERT INTO table_registry (
  table_name, purpose, project, owner_agent, source_task_id,
  schema_version, status, created_at, updated_at
) VALUES (
  'api_endpoints', '记录 API 端点元信息，用于检索认证要求与限流规则',
  'global', 'User', 'TBD', 1, 'active', datetime('now'), datetime('now')
);

-- 示例3：登记字段语义
INSERT INTO column_registry (table_name, column_name, data_type, meaning, is_required, pii_level, created_at, updated_at) VALUES
('api_endpoints', 'id', 'INTEGER', '主键', 1, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'path', 'TEXT', '接口路径', 1, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'method', 'TEXT', 'HTTP 方法', 1, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'requires_auth', 'INTEGER', '是否需要认证', 1, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'rate_limit', 'TEXT', '限流策略', 0, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'source_path', 'TEXT', '来源文件路径', 0, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'source_ref', 'TEXT', '来源定位', 0, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'task_id', 'TEXT', '关联任务 ID', 0, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'created_at', 'TEXT', '创建时间', 1, 'none', datetime('now'), datetime('now')),
('api_endpoints', 'updated_at', 'TEXT', '更新时间', 1, 'none', datetime('now'), datetime('now'));

-- 示例4：写入 DDL 日志
INSERT INTO change_log (table_name, action, actor, task_id, summary, ddl_sql, created_at)
VALUES (
  'api_endpoints', 'create_table', 'User', 'TBD',
  '创建 API 端点元信息表并完成元数据登记',
  'CREATE TABLE api_endpoints (...);', datetime('now')
);

-- 示例5：查询需要认证的 POST 端点
SELECT path, method, requires_auth
FROM api_endpoints
WHERE method = 'POST' AND requires_auth = 1
ORDER BY path;
