-- ============================================
-- 添加录用部门字段到 recruitment_process 表
-- ============================================

-- 1. 添加 hire_department 字段
ALTER TABLE recruitment_process
ADD COLUMN IF NOT EXISTS hire_department VARCHAR(255);

-- 2. 添加 hire_position 字段（如果也不存在）
ALTER TABLE recruitment_process
ADD COLUMN IF NOT EXISTS hire_position VARCHAR(255);

-- 3. 验证字段添加成功
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
AND column_name IN ('hire_department', 'hire_position')
ORDER BY column_name;

-- 4. 查看表的所有字段
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'recruitment_process'
ORDER BY ordinal_position;
