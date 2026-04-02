-- ============================================
-- 升级 applications 表，支持 JSON 动态字段存储
-- 解决字段名包含空格和特殊字符的问题
-- ============================================

-- 添加 JSON 字段来存储动态表单数据
ALTER TABLE applications ADD COLUMN IF NOT EXISTS dynamic_fields JSONB;

-- 创建索引以提高 JSON 查询性能
CREATE INDEX IF NOT EXISTS idx_applications_dynamic_fields ON applications USING GIN (dynamic_fields);

-- 添加兼容旧字段的视图（可选）
COMMENT ON COLUMN applications.dynamic_fields IS '存储动态表单字段的 JSON 数据';

-- 完成
SELECT 'applications 表升级成功！现在支持任意名称的动态字段。' as message;
