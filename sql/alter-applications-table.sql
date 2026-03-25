-- ============================================
-- 义齿工厂面试预约系统 - 扩展applications表结构
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 添加岗位类型字段
ALTER TABLE applications ADD COLUMN IF NOT EXISTS job_type VARCHAR(50);

-- 为学徒/普工模板添加字段
ALTER TABLE applications ADD COLUMN IF NOT EXISTS education_background TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS work_willingness TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS expectation TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS availability TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS hobbies TEXT;

-- 为牙科技工/质检员模板添加字段
ALTER TABLE applications ADD COLUMN IF NOT EXISTS professional_skills TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS certificates TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS work_years TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS previous_company TEXT;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS portfolio TEXT;

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_applications_job_type ON applications(job_type);

-- 完成
SELECT 'applications表扩展成功！' as message;