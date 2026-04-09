-- ============================================
-- 修复 RLS 策略导致的 500 错误
-- ============================================

-- 1. 修复 positions 表
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;

-- 删除所有现有策略
DROP POLICY IF EXISTS "Allow authenticated read positions" ON positions;
DROP POLICY IF EXISTS "Allow admin manage positions" ON positions;
DROP POLICY IF EXISTS "Allow anonymous read positions" ON positions;

-- 创建简单策略：允许所有人读取（先恢复功能）
CREATE POLICY "Allow all read positions"
ON positions FOR SELECT
TO anon, authenticated
USING (true);

-- 允许认证用户管理
CREATE POLICY "Allow authenticated manage positions"
ON positions FOR ALL
TO authenticated
USING (true);

-- 2. 修复 job_types 表
ALTER TABLE job_types ENABLE ROW LEVEL SECURITY;

-- 删除所有现有策略
DROP POLICY IF EXISTS "Allow authenticated read job_types" ON job_types;
DROP POLICY IF EXISTS "Allow admin manage job_types" ON job_types;
DROP POLICY IF EXISTS "Allow anonymous read job_types" ON job_types;

-- 创建简单策略：允许所有人读取
CREATE POLICY "Allow all read job_types"
ON job_types FOR SELECT
TO anon, authenticated
USING (true);

-- 允许认证用户管理
CREATE POLICY "Allow authenticated manage job_types"
ON job_types FOR ALL
TO authenticated
USING (true);

-- 3. 确保其他表的策略正确
-- applications 表
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read applications" ON applications;
DROP POLICY IF EXISTS "Allow authenticated insert applications" ON applications;
DROP POLICY IF EXISTS "Allow authenticated update applications" ON applications;
DROP POLICY IF EXISTS "Allow authenticated delete applications" ON applications;
DROP POLICY IF EXISTS "Allow anonymous insert applications" ON applications;

CREATE POLICY "Allow authenticated full access applications"
ON applications FOR ALL
TO authenticated
USING (true);

CREATE POLICY "Allow anonymous insert applications"
ON applications FOR INSERT
TO anon
WITH CHECK (true);

-- bookings 表
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated read bookings" ON bookings;
DROP POLICY IF EXISTS "Allow authenticated manage bookings" ON bookings;
DROP POLICY IF EXISTS "Allow anonymous insert bookings" ON bookings;

CREATE POLICY "Allow authenticated full access bookings"
ON bookings FOR ALL
TO authenticated
USING (true);

CREATE POLICY "Allow anonymous insert bookings"
ON bookings FOR INSERT
TO anon
WITH CHECK (true);

-- recruitment_process 表
ALTER TABLE recruitment_process ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated full access recruitment_process" ON recruitment_process;

CREATE POLICY "Allow authenticated full access recruitment_process"
ON recruitment_process FOR ALL
TO authenticated
USING (true);

-- 4. 验证策略是否创建成功
SELECT tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('positions', 'job_types', 'applications', 'bookings', 'recruitment_process')
ORDER BY tablename, policyname;
