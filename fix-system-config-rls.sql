-- ============================================
-- 修复 system_config 表的 RLS 策略
-- ============================================

-- 1. 确保 RLS 已启用
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

-- 2. 删除所有现有策略
DROP POLICY IF EXISTS "Allow authenticated read system_config" ON system_config;
DROP POLICY IF EXISTS "Allow admin manage system_config" ON system_config;
DROP POLICY IF EXISTS "Allow anonymous read system_config" ON system_config;
DROP POLICY IF EXISTS "Allow all read system_config" ON system_config;

-- 3. 创建简单策略：允许所有人读取（前端页面需要）
CREATE POLICY "Allow all read system_config"
ON system_config FOR SELECT
TO anon, authenticated
USING (true);

-- 4. 允许认证用户管理
CREATE POLICY "Allow authenticated manage system_config"
ON system_config FOR ALL
TO authenticated
USING (true);

-- 5. 验证策略
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'system_config';
