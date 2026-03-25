-- ============================================
-- 义齿工厂面试预约系统 - 预约表创建脚本
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 创建预约表
CREATE TABLE IF NOT EXISTS bookings (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  position VARCHAR(100),
  booking_date DATE NOT NULL,
  time_slot VARCHAR(50) NOT NULL,
  notes TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_time_slot ON bookings(time_slot);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_phone ON bookings(phone);

-- 设置行级安全策略
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 允许匿名读取和插入
CREATE POLICY "Allow anonymous select on bookings" ON bookings
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on bookings" ON bookings
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on bookings" ON bookings
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on bookings" ON bookings
  FOR DELETE TO anon USING (true);

-- 完成
SELECT '预约表创建成功！' as message;