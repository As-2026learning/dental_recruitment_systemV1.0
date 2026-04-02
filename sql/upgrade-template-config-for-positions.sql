-- ============================================
-- 义齿工厂面试预约系统 - 岗位字段配置表升级脚本
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 备份现有数据（可选）
CREATE TABLE IF NOT EXISTS template_configs_backup AS
SELECT * FROM template_configs;

-- 修改 template_configs 表，添加 position_id 字段
ALTER TABLE template_configs 
ADD COLUMN IF NOT EXISTS position_id INTEGER;

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_template_configs_position ON template_configs(position_id);

-- 更新说明
SELECT '数据库升级成功！现在 template_configs 表支持岗位级别的字段配置。' as message;
SELECT '您可以使用 position_id 字段为每个岗位配置不同的字段。' as instruction;