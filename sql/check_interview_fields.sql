-- 检查 recruitment_process 表中的 interview 相关字段
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
AND (column_name LIKE '%interview%' OR column_name LIKE '%date%' OR column_name LIKE '%time%')
ORDER BY column_name;

-- 检查 applications 表中的 interview 相关字段
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'applications'
AND (column_name LIKE '%interview%' OR column_name LIKE '%date%' OR column_name LIKE '%time%')
ORDER BY column_name;
