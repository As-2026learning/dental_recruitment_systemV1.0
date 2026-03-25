-- ============================================
-- 义齿工厂面试预约系统 - 配置表创建脚本
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 1. 创建岗位配置表
CREATE TABLE IF NOT EXISTS positions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. 创建时段配置表
CREATE TABLE IF NOT EXISTS time_slots (
  id SERIAL PRIMARY KEY,
  slot_key VARCHAR(50) NOT NULL UNIQUE,
  label VARCHAR(100) NOT NULL,
  start_time VARCHAR(10) NOT NULL,
  end_time VARCHAR(10) NOT NULL,
  capacity INT NOT NULL,
  sort_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. 创建系统配置表（存储温馨提示等）
CREATE TABLE IF NOT EXISTS system_config (
  id SERIAL PRIMARY KEY,
  config_key VARCHAR(100) NOT NULL UNIQUE,
  config_value TEXT,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. 插入默认岗位数据
INSERT INTO positions (name, sort_order, is_active) VALUES
('义齿设计师', 1, true),
('CAD/CAM技术员', 2, true),
('模型制作员', 3, true),
('烤瓷技术员', 4, true),
('质检员', 5, true),
('生产主管', 6, true),
('其他', 99, true);

-- 5. 插入新的时段配置
INSERT INTO time_slots (slot_key, label, start_time, end_time, capacity, sort_order, is_active) VALUES
('slot_1', '上午场 09:00-10:00', '09:00', '10:00', 10, 1, true),
('slot_2', '上午场 10:00-10:30', '10:00', '10:30', 5, 2, true),
('slot_3', '下午场 13:00-14:00', '13:00', '14:00', 10, 3, true),
('slot_4', '下午场 14:00-15:00', '14:00', '15:00', 10, 4, true),
('slot_5', '下午场 15:00-15:30', '15:00', '15:30', 5, 5, true);

-- 6. 插入默认温馨提示和横幅文本
INSERT INTO system_config (config_key, config_value, description) VALUES
('success_tips', '请携带身份证原件准时到达|如需修改或取消预约，请致电：XXX-XXXX-XXXX|面试地点：XXXXXXXXXXXXXXXX', '预约成功页面温馨提示'),
('booking_notice', '面试时间：周一至周五|请提前至少2小时预约|请确保联系方式正确', '预约须知'),
('banner_settings', '系统设置', '设置页面横幅文本'),
('banner_booking', '义齿工厂面试预约', '预约页面横幅文本'),
('banner_admin', '预约管理', '管理页面横幅文本');

-- 7. 设置行级安全策略
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- 8. 允许匿名读取配置
CREATE POLICY "Allow anonymous select on positions" ON positions
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous select on time_slots" ON time_slots
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous select on system_config" ON system_config
  FOR SELECT TO anon USING (true);

-- 9. 允许匿名更新配置（用于后台管理）
CREATE POLICY "Allow anonymous insert on positions" ON positions
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on positions" ON positions
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on positions" ON positions
  FOR DELETE TO anon USING (true);

CREATE POLICY "Allow anonymous insert on time_slots" ON time_slots
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on time_slots" ON time_slots
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on time_slots" ON time_slots
  FOR DELETE TO anon USING (true);

CREATE POLICY "Allow anonymous insert on system_config" ON system_config
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on system_config" ON system_config
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- 完成
SELECT '配置表创建成功！' as message;
