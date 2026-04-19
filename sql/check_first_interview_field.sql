-- 检查 first_interview 和 second_interview 字段的类型
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
AND column_name IN ('first_interview', 'second_interview')
ORDER BY column_name;

-- 检查所有字段
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
ORDER BY ordinal_position;
