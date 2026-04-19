-- ============================================
-- 简化版本：仅创建普通索引（不唯一）
-- 避免重复数据检查导致的超时
-- ============================================

-- 创建普通索引（提升查询性能，不强制唯一性）
CREATE INDEX IF NOT EXISTS idx_name_phone 
ON recruitment_process(name, phone);

CREATE INDEX IF NOT EXISTS idx_name_idcard 
ON recruitment_process(name, id_card);

CREATE INDEX IF NOT EXISTS idx_application_id 
ON recruitment_process(application_id);

-- 验证索引创建
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'recruitment_process';
