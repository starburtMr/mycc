PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

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
