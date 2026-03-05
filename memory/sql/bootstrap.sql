PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS table_registry (
  table_name TEXT PRIMARY KEY,
  purpose TEXT NOT NULL,
  project TEXT NOT NULL DEFAULT 'global',
  owner_agent TEXT NOT NULL CHECK (owner_agent IN ('Claude','Codex','User')),
  source_task_id TEXT,
  schema_version INTEGER NOT NULL DEFAULT 1 CHECK (schema_version >= 1),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','deprecated')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS column_registry (
  table_name TEXT NOT NULL,
  column_name TEXT NOT NULL,
  data_type TEXT NOT NULL,
  meaning TEXT NOT NULL,
  is_required INTEGER NOT NULL DEFAULT 0 CHECK (is_required IN (0,1)),
  pii_level TEXT NOT NULL DEFAULT 'none' CHECK (pii_level IN ('none','low','high')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (table_name, column_name),
  FOREIGN KEY (table_name) REFERENCES table_registry(table_name) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS change_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('create_table','alter_table','deprecate_table','register_columns')),
  actor TEXT NOT NULL CHECK (actor IN ('Claude','Codex','User')),
  task_id TEXT,
  summary TEXT NOT NULL,
  ddl_sql TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (table_name) REFERENCES table_registry(table_name) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_table_registry_project_status
  ON table_registry (project, status);

CREATE INDEX IF NOT EXISTS idx_change_log_table_created_at
  ON change_log (table_name, created_at);

CREATE VIEW IF NOT EXISTS v_active_tables AS
SELECT table_name, purpose, project, owner_agent, schema_version, updated_at
FROM table_registry
WHERE status = 'active';

CREATE TABLE IF NOT EXISTS fact_memory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  source TEXT NOT NULL,
  source_task_id TEXT,
  confidence REAL NOT NULL DEFAULT 0.6 CHECK (confidence >= 0.0 AND confidence <= 1.0),
  ttl_days INTEGER NOT NULL DEFAULT 30 CHECK (ttl_days >= 1 AND ttl_days <= 3650),
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  UNIQUE(key, source)
);

CREATE TABLE IF NOT EXISTS working_memory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  topic TEXT NOT NULL,
  content TEXT NOT NULL,
  source TEXT NOT NULL,
  source_task_id TEXT,
  confidence REAL NOT NULL DEFAULT 0.6 CHECK (confidence >= 0.0 AND confidence <= 1.0),
  ttl_days INTEGER NOT NULL DEFAULT 7 CHECK (ttl_days >= 1 AND ttl_days <= 365),
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_fact_memory_expires_at
  ON fact_memory (expires_at);
CREATE INDEX IF NOT EXISTS idx_working_memory_session_expires
  ON working_memory (session_id, expires_at);

COMMIT;
