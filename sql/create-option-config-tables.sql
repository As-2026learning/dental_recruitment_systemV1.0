-- 创建字段选项配置表
CREATE TABLE IF NOT EXISTS field_option_configs (
  id SERIAL PRIMARY KEY,
  field_id INTEGER NOT NULL REFERENCES template_configs(id) ON DELETE CASCADE,
  option_value VARCHAR(255) NOT NULL,
  option_label VARCHAR(255) NOT NULL,
  has_attachments BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建附加信息配置表
CREATE TABLE IF NOT EXISTS attachment_configs (
  id SERIAL PRIMARY KEY,
  option_config_id INTEGER NOT NULL REFERENCES field_option_configs(id) ON DELETE CASCADE,
  field_name VARCHAR(100) NOT NULL,
  field_label VARCHAR(100) NOT NULL,
  field_type VARCHAR(50) NOT NULL, -- text, textarea, date, number
  is_required BOOLEAN DEFAULT false,
  validation_rules JSONB,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建应用附加信息表
CREATE TABLE IF NOT EXISTS application_attachments (
  id SERIAL PRIMARY KEY,
  application_id INTEGER NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  option_config_id INTEGER NOT NULL REFERENCES field_option_configs(id),
  attachment_config_id INTEGER NOT NULL REFERENCES attachment_configs(id),
  value TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_field_option_configs_field ON field_option_configs(field_id);
CREATE INDEX IF NOT EXISTS idx_attachment_configs_option ON attachment_configs(option_config_id);
CREATE INDEX IF NOT EXISTS idx_application_attachments_application ON application_attachments(application_id);

-- 设置行级安全策略
ALTER TABLE field_option_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachment_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE application_attachments ENABLE ROW LEVEL SECURITY;

-- 允许匿名读取和写入
CREATE POLICY "Allow anonymous select on field_option_configs" ON field_option_configs
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on field_option_configs" ON field_option_configs
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on field_option_configs" ON field_option_configs
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on field_option_configs" ON field_option_configs
  FOR DELETE TO anon USING (true);

CREATE POLICY "Allow anonymous select on attachment_configs" ON attachment_configs
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on attachment_configs" ON attachment_configs
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on attachment_configs" ON attachment_configs
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on attachment_configs" ON attachment_configs
  FOR DELETE TO anon USING (true);

CREATE POLICY "Allow anonymous select on application_attachments" ON application_attachments
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on application_attachments" ON application_attachments
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on application_attachments" ON application_attachments
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on application_attachments" ON application_attachments
  FOR DELETE TO anon USING (true);

-- 完成
SELECT '选项配置表创建成功！' as message;