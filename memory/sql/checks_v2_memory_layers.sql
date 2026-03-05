-- 巡检4：分层记忆字段合法性（仅在 fact_memory/working_memory 存在时运行）
SELECT 'fact_memory_invalid' AS issue, id
FROM fact_memory
WHERE confidence < 0 OR confidence > 1
   OR ttl_days < 1
   OR source IS NULL
   OR source = '';

SELECT 'working_memory_invalid' AS issue, id
FROM working_memory
WHERE confidence < 0 OR confidence > 1
   OR ttl_days < 1
   OR session_id IS NULL
   OR session_id = ''
   OR source IS NULL
   OR source = '';
