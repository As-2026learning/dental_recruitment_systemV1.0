-- 检查 recruitment_process 表中的 interview_date 和 interview_time_slot 字段
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
AND column_name IN ('interview_date', 'interview_time_slot')
ORDER BY column_name;

-- 检查 applications 表中的 interview_date 和 interview_time_slot 字段
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'applications'
AND column_name IN ('interview_date', 'interview_time_slot')
ORDER BY column_name;
