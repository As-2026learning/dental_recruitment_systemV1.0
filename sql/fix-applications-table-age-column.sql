-- ============================================
-- 修复 applications 表的 Age 列问题
-- 同时确保大小写兼容
-- ============================================

-- 检查并添加 Age 列（大写开头）以保持兼容性
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Age" INT;

-- 如果 age 列有数据，同步到 Age 列
UPDATE applications SET "Age" = age WHERE "Age" IS NULL AND age IS NOT NULL;

-- 同时添加其他可能的大小写变体以确保兼容性
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Name" VARCHAR(100);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Gender" VARCHAR(10);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Phone" VARCHAR(20);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Position" VARCHAR(100);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Education" VARCHAR(50);
ALTER TABLE applications ADD COLUMN IF NOT EXISTS "Experience" VARCHAR(50);

-- 同步数据到大写列
UPDATE applications SET "Name" = name WHERE "Name" IS NULL AND name IS NOT NULL;
UPDATE applications SET "Gender" = gender WHERE "Gender" IS NULL AND gender IS NOT NULL;
UPDATE applications SET "Phone" = phone WHERE "Phone" IS NULL AND phone IS NOT NULL;
UPDATE applications SET "Position" = position WHERE "Position" IS NULL AND position IS NOT NULL;
UPDATE applications SET "Education" = education WHERE "Education" IS NULL AND education IS NOT NULL;
UPDATE applications SET "Experience" = experience WHERE "Experience" IS NULL AND experience IS NOT NULL;

-- 完成
SELECT 'applications 表兼容性修复完成！' as message;
