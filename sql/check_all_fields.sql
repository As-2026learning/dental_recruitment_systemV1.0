-- 检查 recruitment_process 表中的所有字段
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
ORDER BY ordinal_position;
