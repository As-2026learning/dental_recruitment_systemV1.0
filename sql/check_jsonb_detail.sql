-- 检查 first_interview 和 second_interview 字段的详细信息
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
AND column_name IN ('first_interview', 'second_interview', 'dynamic_fields')
ORDER BY column_name;

-- 检查这些字段的实际数据
SELECT 
    id,
    name,
    first_interview,
    second_interview,
    dynamic_fields
FROM recruitment_process
WHERE first_interview IS NOT NULL 
   OR second_interview IS NOT NULL 
   OR dynamic_fields IS NOT NULL
LIMIT 5;
