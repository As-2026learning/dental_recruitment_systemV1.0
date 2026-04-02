-- ============================================
-- 义齿工厂面试预约系统 - 预约表结构更新
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 更新预约表，添加关联字段
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS application_id INTEGER REFERENCES applications(id) ON DELETE CASCADE;

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_bookings_application_id ON bookings(application_id);

-- 完成
SELECT '预约表结构更新成功！' as message;