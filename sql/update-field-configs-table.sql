-- ============================================
-- 义齿工厂招聘系统 - 字段配置表结构更新
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 更新字段配置表，添加前端显示控制字段
ALTER TABLE public.field_configs
ADD COLUMN IF NOT EXISTS is_frontend BOOLEAN DEFAULT true;

-- 完成
SELECT '字段配置表结构更新成功！' as message;