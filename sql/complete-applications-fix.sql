-- ============================================
-- 完整修复 applications 表结构
-- 添加所有必需的列以支持当前前端代码
-- ============================================

-- 1. 添加 position_id 列
ALTER TABLE applications ADD COLUMN IF NOT EXISTS position_id INT;

-- 2. 添加 position_name 列
ALTER TABLE applications ADD COLUMN IF NOT EXISTS position_name VARCHAR(100);

-- 3. 添加 JSON 字段存储动态数据
ALTER TABLE applications ADD COLUMN IF NOT EXISTS dynamic_fields JSONB;

-- 4. 添加大写开头的兼容列（解决 Age 等问题）
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Age" INT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Name" VARCHAR(100);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Gender" VARCHAR(10);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Phone" VARCHAR(20);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Position" VARCHAR(100);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Education" VARCHAR(50);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Experience" VARCHAR(50);

-- 5. 同步现有数据（如果有）
UPDATE applications SET position_name = position WHERE position_name IS NULL AND position IS NOT NULL;
UPDATE applications SET "Age" = age WHERE "Age" IS NULL AND age IS NOT NULL;
UPDATE applications SET "Name" = name WHERE "Name" IS NULL AND name IS NOT NULL;
UPDATE applications SET "Gender" = gender WHERE "Gender" IS NULL AND gender IS NOT NULL;
UPDATE applications SET "Phone" = phone WHERE "Phone" IS NULL AND phone IS NOT NULL;
UPDATE applications SET "Position" = position WHERE "Position" IS NULL AND position IS NOT NULL;
UPDATE applications SET "Education" = education WHERE "Education" IS NULL AND education IS NOT NULL;
UPDATE applications SET "Experience" = experience WHERE "Experience" IS NULL AND experience IS NOT NULL;

-- 6. 创建索引
CREATE INDEX IF NOT EXISTS idx_applications_position_id ON applications(position_id);
CREATE INDEX IF NOT EXISTS idx_applications_dynamic_fields ON applications USING GIN (dynamic_fields);

-- 完成
SELECT 'applications 表结构修复完成！已添加 position_id, position_name, dynamic_fields 等列。' as message;
