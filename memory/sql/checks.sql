PRAGMA foreign_keys = ON;

-- 巡检1：找出未登记业务表（排除 sqlite 内部表和固定系统表）
SELECT m.name AS unregistered_table
FROM sqlite_master m
LEFT JOIN table_registry r ON r.table_name = m.name
WHERE m.type = 'table'
  AND m.name NOT LIKE 'sqlite_%'
  AND m.name NOT IN ('table_registry', 'column_registry', 'change_log')
  AND r.table_name IS NULL;

-- 巡检2：登记为 active 但数据库中不存在的表
SELECT r.table_name AS missing_physical_table
FROM table_registry r
LEFT JOIN sqlite_master m ON m.type = 'table' AND m.name = r.table_name
WHERE r.status = 'active'
  AND m.name IS NULL;

-- 巡检3：字段未登记（仅检查 active 表，排除固定系统表）
WITH active_tables AS (
  SELECT table_name
  FROM table_registry
  WHERE status = 'active'
),
physical_cols AS (
  SELECT at.table_name, p.name AS column_name
  FROM active_tables at
  JOIN pragma_table_info(at.table_name) p
)
SELECT pc.table_name, pc.column_name
FROM physical_cols pc
LEFT JOIN column_registry cr
  ON cr.table_name = pc.table_name
 AND cr.column_name = pc.column_name
WHERE pc.table_name NOT IN ('table_registry', 'column_registry', 'change_log')
  AND cr.column_name IS NULL
ORDER BY pc.table_name, pc.column_name;
