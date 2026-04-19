-- ============================================
-- 招聘流程管理模块 - 添加唯一约束防止重复数据
-- 执行方案一：数据库层面防护
-- ============================================

-- 说明：以下SQL语句需要在Supabase控制台(SQL编辑器)中执行
-- 这些约束将从数据库层面防止重复数据的产生

-- ----------------------------------------------------
-- 1. 添加基于姓名+手机号的唯一索引
-- 说明：当手机号存在且不为空时，确保姓名+手机号组合唯一
-- ----------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_name_phone 
ON recruitment_process(name, phone) 
WHERE phone IS NOT NULL AND phone != '';

-- ----------------------------------------------------
-- 2. 添加基于姓名+身份证号的唯一索引
-- 说明：当身份证号存在且不为空时，确保姓名+身份证号组合唯一
-- ----------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_name_idcard 
ON recruitment_process(name, id_card) 
WHERE id_card IS NOT NULL AND id_card != '';

-- ----------------------------------------------------
-- 3. 添加基于application_id的唯一索引（如果适用）
-- 说明：确保同一个application_id只对应一条记录
-- ----------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_application_id 
ON recruitment_process(application_id) 
WHERE application_id IS NOT NULL;

-- ----------------------------------------------------
-- 验证索引是否创建成功
-- ----------------------------------------------------
SELECT 
    indexname,
    indexdef
FROM 
    pg_indexes
WHERE 
    tablename = 'recruitment_process'
    AND indexname LIKE 'idx_unique_%'
ORDER BY 
    indexname;

-- ----------------------------------------------------
-- 注意事项：
-- 1. 如果表中已存在重复数据，需要先清理重复数据才能成功创建唯一索引
-- 2. 可以使用以下查询检查是否存在重复数据：
-- ----------------------------------------------------

-- 检查姓名+手机号重复
SELECT name, phone, COUNT(*) as count
FROM recruitment_process
WHERE phone IS NOT NULL AND phone != ''
GROUP BY name, phone
HAVING COUNT(*) > 1;

-- 检查姓名+身份证号重复
SELECT name, id_card, COUNT(*) as count
FROM recruitment_process
WHERE id_card IS NOT NULL AND id_card != ''
GROUP BY name, id_card
HAVING COUNT(*) > 1;

-- 检查application_id重复
SELECT application_id, COUNT(*) as count
FROM recruitment_process
WHERE application_id IS NOT NULL
GROUP BY application_id
HAVING COUNT(*) > 1;
