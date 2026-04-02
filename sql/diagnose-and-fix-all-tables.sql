-- 诊断和修复所有表结构的SQL脚本

-- 1. 检查并创建applications表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'applications') THEN
    CREATE TABLE applications (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255),
      phone VARCHAR(50),
      position VARCHAR(255),
      gender VARCHAR(10),
      age INTEGER,
      education VARCHAR(100),
      experience VARCHAR(100),
      job_type VARCHAR(50),
      status VARCHAR(20) DEFAULT 'pending',
      dynamic_fields JSONB,
      form_data JSONB,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加索引
    CREATE INDEX idx_applications_phone ON applications(phone);
    CREATE INDEX idx_applications_position ON applications(position);
    CREATE INDEX idx_applications_status ON applications(status);
    CREATE INDEX idx_applications_created_at ON applications(created_at);
  END IF;
END $$;

-- 2. 检查并创建bookings表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'bookings') THEN
    CREATE TABLE bookings (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      phone VARCHAR(50) NOT NULL,
      position VARCHAR(255),
      booking_date DATE NOT NULL,
      time_slot VARCHAR(50) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      application_id INTEGER REFERENCES applications(id),
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加索引
    CREATE INDEX idx_bookings_phone ON bookings(phone);
    CREATE INDEX idx_bookings_date ON bookings(booking_date);
    CREATE INDEX idx_bookings_status ON bookings(status);
    CREATE INDEX idx_bookings_application_id ON bookings(application_id);
  END IF;
END $$;

-- 3. 检查并创建positions表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'positions') THEN
    CREATE TABLE positions (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      sort_order INTEGER DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加索引
    CREATE INDEX idx_positions_sort_order ON positions(sort_order);
    CREATE INDEX idx_positions_is_active ON positions(is_active);
  END IF;
END $$;

-- 4. 检查并创建time_slots表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'time_slots') THEN
    CREATE TABLE time_slots (
      id SERIAL PRIMARY KEY,
      slot_key VARCHAR(50) NOT NULL,
      label VARCHAR(255) NOT NULL,
      start_time TIME NOT NULL,
      end_time TIME NOT NULL,
      capacity INTEGER DEFAULT 10,
      sort_order INTEGER DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加索引
    CREATE INDEX idx_time_slots_sort_order ON time_slots(sort_order);
    CREATE INDEX idx_time_slots_is_active ON time_slots(is_active);
  END IF;
END $$;

-- 5. 检查并创建templates表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'templates') THEN
    CREATE TABLE templates (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      description TEXT,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
  END IF;
END $$;

-- 6. 检查并创建field_configs表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'field_configs') THEN
    CREATE TABLE field_configs (
      id SERIAL PRIMARY KEY,
      field_name VARCHAR(100) NOT NULL,
      field_label VARCHAR(255) NOT NULL,
      field_type VARCHAR(50) NOT NULL,
      is_required BOOLEAN DEFAULT false,
      default_value TEXT,
      validation_rule VARCHAR(100),
      is_frontend BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
  END IF;
END $$;

-- 7. 检查并创建field_options表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'field_options') THEN
    CREATE TABLE field_options (
      id SERIAL PRIMARY KEY,
      field_id INTEGER REFERENCES field_configs(id),
      label VARCHAR(255) NOT NULL,
      value VARCHAR(255) NOT NULL,
      sort_order INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加索引
    CREATE INDEX idx_field_options_field_id ON field_options(field_id);
  END IF;
END $$;

-- 8. 检查并创建template_field_mappings表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'template_field_mappings') THEN
    CREATE TABLE template_field_mappings (
      id SERIAL PRIMARY KEY,
      template_id INTEGER REFERENCES templates(id),
      field_id INTEGER REFERENCES field_configs(id),
      sort_order INTEGER DEFAULT 0,
      is_enabled BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加索引
    CREATE INDEX idx_template_field_mappings_template_id ON template_field_mappings(template_id);
  END IF;
END $$;

-- 9. 检查并创建system_config表
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_config') THEN
    CREATE TABLE system_config (
      id SERIAL PRIMARY KEY,
      config_key VARCHAR(100) NOT NULL UNIQUE,
      config_value TEXT,
      description TEXT,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    );
    
    -- 添加唯一约束
    ALTER TABLE system_config ADD CONSTRAINT unique_config_key UNIQUE(config_key);
  END IF;
END $$;

-- 10. 插入默认数据

-- 插入默认岗位
INSERT INTO positions (name, sort_order, is_active) VALUES
('口腔医生', 1, true),
('牙科技工', 2, true),
('口腔护士', 3, true),
('前台接待', 4, true),
('市场专员', 5, true)
ON CONFLICT DO NOTHING;

-- 插入默认时段
INSERT INTO time_slots (slot_key, label, start_time, end_time, capacity, sort_order, is_active) VALUES
('slot_1', '上午场 09:00-10:00', '09:00', '10:00', 10, 1, true),
('slot_2', '上午场 10:00-10:30', '10:00', '10:30', 5, 2, true),
('slot_3', '下午场 13:00-14:00', '13:00', '14:00', 10, 3, true),
('slot_4', '下午场 14:00-15:00', '14:00', '15:00', 10, 4, true),
('slot_5', '下午场 15:00-15:30', '15:00', '15:30', 5, 5, true)
ON CONFLICT DO NOTHING;

-- 插入默认模板
INSERT INTO templates (name, description, is_active) VALUES
('基础模板', '包含基本个人信息字段', true),
('技术岗位模板', '包含技术技能相关字段', true)
ON CONFLICT DO NOTHING;

-- 插入默认字段配置
INSERT INTO field_configs (field_name, field_label, field_type, is_required, validation_rule, is_frontend) VALUES
('name', '姓名', 'text', true, '', true),
('gender', '性别', 'radio', true, '', true),
('age', '年龄', 'number', true, 'number', true),
('phone', '联系电话', 'text', true, 'phone', true),
('education', '学历', 'select', true, '', true),
('experience', '工作经验', 'select', true, '', true),
('source_channel', '招聘渠道', 'select', true, '', true),
('self_introduction', '自我介绍', 'textarea', false, '', true)
ON CONFLICT DO NOTHING;

-- 插入字段选项
INSERT INTO field_options (field_id, label, value, sort_order) VALUES
-- 性别选项
((SELECT id FROM field_configs WHERE field_name = 'gender'), '男', '男', 1),
((SELECT id FROM field_configs WHERE field_name = 'gender'), '女', '女', 2),
-- 学历选项
((SELECT id FROM field_configs WHERE field_name = 'education'), '初中及以下', '初中及以下', 1),
((SELECT id FROM field_configs WHERE field_name = 'education'), '高中/中专', '高中/中专', 2),
((SELECT id FROM field_configs WHERE field_name = 'education'), '大专', '大专', 3),
((SELECT id FROM field_configs WHERE field_name = 'education'), '本科', '本科', 4),
((SELECT id FROM field_configs WHERE field_name = 'education'), '研究生及以上', '研究生及以上', 5),
-- 工作经验选项
((SELECT id FROM field_configs WHERE field_name = 'experience'), '无经验', '无经验', 1),
((SELECT id FROM field_configs WHERE field_name = 'experience'), '1年以下', '1年以下', 2),
((SELECT id FROM field_configs WHERE field_name = 'experience'), '1-3年', '1-3年', 3),
((SELECT id FROM field_configs WHERE field_name = 'experience'), '3-5年', '3-5年', 4),
((SELECT id FROM field_configs WHERE field_name = 'experience'), '5年以上', '5年以上', 5),
-- 招聘渠道选项
((SELECT id FROM field_configs WHERE field_name = 'source_channel'), '内部介绍', '内部介绍', 1),
((SELECT id FROM field_configs WHERE field_name = 'source_channel'), '招聘网站', '招聘网站', 2),
((SELECT id FROM field_configs WHERE field_name = 'source_channel'), '社交媒体', '社交媒体', 3),
((SELECT id FROM field_configs WHERE field_name = 'source_channel'), '线下招聘', '线下招聘', 4),
((SELECT id FROM field_configs WHERE field_name = 'source_channel'), '其他', '其他', 5)
ON CONFLICT DO NOTHING;

-- 插入模板字段映射
INSERT INTO template_field_mappings (template_id, field_id, sort_order, is_enabled) VALUES
-- 基础模板字段
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'name'), 1, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'gender'), 2, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'age'), 3, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'phone'), 4, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'education'), 5, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'experience'), 6, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'source_channel'), 7, true),
((SELECT id FROM templates WHERE name = '基础模板'), (SELECT id FROM field_configs WHERE field_name = 'self_introduction'), 8, true),
-- 技术岗位模板字段
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'name'), 1, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'gender'), 2, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'age'), 3, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'phone'), 4, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'education'), 5, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'experience'), 6, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'source_channel'), 7, true),
((SELECT id FROM templates WHERE name = '技术岗位模板'), (SELECT id FROM field_configs WHERE field_name = 'self_introduction'), 8, true)
ON CONFLICT DO NOTHING;

-- 插入系统配置默认值
INSERT INTO system_config (config_key, config_value, description) VALUES
('booking_notice', '面试时间：周一至周五|请提前至少2小时预约|请确保联系方式正确', '预约须知'),
('success_tips', '请携带身份证原件准时到达|如需修改或取消预约，请致电：XXX-XXXX-XXXX|面试地点：XXXXXXXXXXXXXXXX', '预约成功提示'),
('banner_settings', '系统设置', '设置页面横幅'),
('banner_booking', '面试预约', '预约页面横幅'),
('banner_admin', '应聘与预约管理', '管理页面横幅')
ON CONFLICT (config_key) DO UPDATE SET config_value = EXCLUDED.config_value;

-- 11. 启用Row Level Security (RLS)

-- 为applications表启用RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to applications" ON applications FOR ALL USING (true);

-- 为bookings表启用RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to bookings" ON bookings FOR ALL USING (true);

-- 为positions表启用RLS
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to positions" ON positions FOR ALL USING (true);

-- 为time_slots表启用RLS
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to time_slots" ON time_slots FOR ALL USING (true);

-- 为templates表启用RLS
ALTER TABLE templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to templates" ON templates FOR ALL USING (true);

-- 为field_configs表启用RLS
ALTER TABLE field_configs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to field_configs" ON field_configs FOR ALL USING (true);

-- 为field_options表启用RLS
ALTER TABLE field_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to field_options" ON field_options FOR ALL USING (true);

-- 为template_field_mappings表启用RLS
ALTER TABLE template_field_mappings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to template_field_mappings" ON template_field_mappings FOR ALL USING (true);

-- 为system_config表启用RLS
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access to system_config" ON system_config FOR ALL USING (true);

-- 12. 优化表结构

-- 为所有表添加updated_at触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为applications表添加触发器
CREATE TRIGGER update_applications_updated_at
BEFORE UPDATE ON applications
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 为bookings表添加触发器
CREATE TRIGGER update_bookings_updated_at
BEFORE UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 为positions表添加触发器
CREATE TRIGGER update_positions_updated_at
BEFORE UPDATE ON positions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 为time_slots表添加触发器
CREATE TRIGGER update_time_slots_updated_at
BEFORE UPDATE ON time_slots
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 为templates表添加触发器
CREATE TRIGGER update_templates_updated_at
BEFORE UPDATE ON templates
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 为field_configs表添加触发器
CREATE TRIGGER update_field_configs_updated_at
BEFORE UPDATE ON field_configs
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 为system_config表添加触发器
CREATE TRIGGER update_system_config_updated_at
BEFORE UPDATE ON system_config
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 13. 分析表以更新统计信息
ANALYZE applications;
ANALYZE bookings;
ANALYZE positions;
ANALYZE time_slots;
ANALYZE templates;
ANALYZE field_configs;
ANALYZE field_options;
ANALYZE template_field_mappings;
ANALYZE system_config;

-- 完成修复
SELECT '所有表结构修复完成' AS status;