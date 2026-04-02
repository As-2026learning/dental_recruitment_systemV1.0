-- ============================================
-- 义齿工厂面试预约系统 - 模板配置表创建脚本
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 创建模板配置表
CREATE TABLE IF NOT EXISTS template_configs (
  id SERIAL PRIMARY KEY,
  template_type VARCHAR(50) NOT NULL, -- apprentice/technician
  field_name VARCHAR(100) NOT NULL,
  field_label VARCHAR(100) NOT NULL,
  field_type VARCHAR(50) NOT NULL, -- text, select, date, textarea, radio, checkbox, number
  is_required BOOLEAN DEFAULT false,
  validation_rules JSONB,
  options TEXT, -- 选项值，用逗号分隔
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_template_configs_type ON template_configs(template_type);
CREATE INDEX IF NOT EXISTS idx_template_configs_order ON template_configs(sort_order);

-- 设置行级安全策略
ALTER TABLE template_configs ENABLE ROW LEVEL SECURITY;

-- 允许匿名读取和写入
CREATE POLICY "Allow anonymous select on template_configs" ON template_configs
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on template_configs" ON template_configs
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on template_configs" ON template_configs
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on template_configs" ON template_configs
  FOR DELETE TO anon USING (true);

-- 插入默认模板配置
-- 学徒/普工模板
INSERT INTO template_configs (template_type, field_name, field_label, field_type, is_required, sort_order)
VALUES
  ('apprentice', 'education_background', '教育背景', 'textarea', true, 1),
  ('apprentice', 'work_willingness', '工作意愿', 'textarea', true, 2),
  ('apprentice', 'expectation', '期望薪资', 'text', true, 3),
  ('apprentice', 'availability', '到岗时间', 'text', false, 4),
  ('apprentice', 'hobbies', '兴趣爱好', 'textarea', false, 5);

-- 牙科技工/质检员模板
INSERT INTO template_configs (template_type, field_name, field_label, field_type, is_required, sort_order)
VALUES
  ('technician', 'professional_skills', '专业技能', 'textarea', true, 1),
  ('technician', 'certificates', '资质证书', 'textarea', true, 2),
  ('technician', 'work_years', '工作年限', 'text', true, 3),
  ('technician', 'previous_company', ' previous_company', 'text', false, 4),
  ('technician', 'portfolio', '作品集', 'textarea', false, 5);

-- 完成
SELECT '模板配置表创建成功！' as message;