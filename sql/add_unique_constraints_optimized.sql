-- ============================================
-- 招聘流程管理模块 - 添加唯一约束（优化版本）
-- 分批处理，避免超时
-- ============================================

-- 步骤1：先检查数据量
SELECT COUNT(*) as total_records FROM recruitment_process;

-- 步骤2：分批检查重复数据（限制返回数量）
-- 检查姓名+手机号重复（限制前100条）
SELECT name, phone, COUNT(*) as count
FROM recruitment_process
WHERE phone IS NOT NULL AND phone != ''
GROUP BY name, phone
HAVING COUNT(*) > 1
LIMIT 100;

-- 步骤3：分批检查application_id重复
SELECT application_id, COUNT(*) as count
FROM recruitment_process
WHERE application_id IS NOT NULL
GROUP BY application_id
HAVING COUNT(*) > 1
LIMIT 100;

-- ============================================
-- 如果以上查询正常执行，再执行以下创建索引语句
-- 注意：如果存在重复数据，创建唯一索引会失败
-- ============================================

-- 创建普通索引（非唯一，先提升查询性能）
CREATE INDEX IF NOT EXISTS idx_name_phone 
ON recruitment_process(name, phone) 
WHERE phone IS NOT NULL AND phone != '';

CREATE INDEX IF NOT EXISTS idx_name_idcard 
ON recruitment_process(name, id_card) 
WHERE id_card IS NOT NULL AND id_card != '';

CREATE INDEX IF NOT EXISTS idx_application_id 
ON recruitment_process(application_id) 
WHERE application_id IS NOT NULL;

-- ============================================
-- 清理重复数据后，再将索引改为唯一索引
-- 执行以下语句前，确保已清理重复数据
-- ============================================

-- 删除普通索引
-- DROP INDEX IF EXISTS idx_name_phone;
-- DROP INDEX IF EXISTS idx_name_idcard;
-- DROP INDEX IF EXISTS idx_application_id;

-- 创建唯一索引（清理重复数据后再执行）
-- CREATE UNIQUE INDEX idx_unique_name_phone 
-- ON recruitment_process(name, phone) 
-- WHERE phone IS NOT NULL AND phone != '';

-- CREATE UNIQUE INDEX idx_unique_name_idcard 
-- ON recruitment_process(name, id_card) 
-- WHERE id_card IS NOT NULL AND id_card != '';

-- CREATE UNIQUE INDEX idx_unique_application_id 
-- ON recruitment_process(application_id) 
-- WHERE application_id IS NOT NULL;
