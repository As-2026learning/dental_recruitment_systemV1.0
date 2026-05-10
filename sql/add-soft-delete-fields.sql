-- ============================================
-- 添加软删除字段到各表
-- 执行此SQL为applications、bookings、recruitment_process表添加软删除支持
-- ============================================

-- 1. 为 applications 表添加软删除字段
ALTER TABLE applications 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS deleted_by TEXT;

-- 创建索引提高查询性能
CREATE INDEX IF NOT EXISTS idx_applications_is_deleted ON applications(is_deleted);
CREATE INDEX IF NOT EXISTS idx_applications_deleted_at ON applications(deleted_at);

-- 2. 为 bookings 表添加软删除字段
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS deleted_by TEXT;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_bookings_is_deleted ON bookings(is_deleted);
CREATE INDEX IF NOT EXISTS idx_bookings_deleted_at ON bookings(deleted_at);

-- 3. 为 recruitment_process 表添加软删除字段
ALTER TABLE recruitment_process 
ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS deleted_by TEXT;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_recruitment_process_is_deleted ON recruitment_process(is_deleted);
CREATE INDEX IF NOT EXISTS idx_recruitment_process_deleted_at ON recruitment_process(deleted_at);

-- 4. 更新RLS策略，允许管理员查看和操作已删除数据
-- 注意：需要在Supabase控制台手动更新RLS策略，或使用Supabase CLI

-- 验证字段是否添加成功
SELECT 
    table_name,
    column_name,
    data_type,
    column_default
FROM 
    information_schema.columns
WHERE 
    table_name IN ('applications', 'bookings', 'recruitment_process')
    AND column_name IN ('is_deleted', 'deleted_at', 'deleted_by')
ORDER BY 
    table_name, ordinal_position;
