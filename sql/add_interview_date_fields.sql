-- ============================================
-- 添加面试日期字段到 recruitment_process 和 applications 表
-- ============================================

-- 1. 添加 interview_date 字段到 recruitment_process 表
ALTER TABLE recruitment_process
ADD COLUMN IF NOT EXISTS interview_date DATE;

-- 2. 添加 interview_time_slot 字段到 recruitment_process 表
ALTER TABLE recruitment_process
ADD COLUMN IF NOT EXISTS interview_time_slot VARCHAR(50);

-- 3. 添加 interview_date 字段到 applications 表
ALTER TABLE applications
ADD COLUMN IF NOT EXISTS interview_date DATE;

-- 4. 添加 interview_time_slot 字段到 applications 表
ALTER TABLE applications
ADD COLUMN IF NOT EXISTS interview_time_slot VARCHAR(50);

-- 5. 验证字段添加成功
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('recruitment_process', 'applications')
AND column_name IN ('interview_date', 'interview_time_slot')
ORDER BY table_name, column_name;
