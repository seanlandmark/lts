SELECT
  id,
  email,
  created_at
FROM your_table_name
WHERE created_at >= '2026-01-01'
ORDER BY created_at DESC
LIMIT 1000;
