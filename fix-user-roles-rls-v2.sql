-- ============================================
-- 修复 user_roles 表的 RLS 策略 - 解决无限递归问题
-- ============================================

-- 1. 禁用 RLS（临时解决）
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;

-- 2. 删除所有现有策略
DROP POLICY IF EXISTS "Allow authenticated read user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow admin manage user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow users read own role" ON user_roles;
DROP POLICY IF EXISTS "Allow authenticated full access user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow all access user_roles" ON user_roles;

-- 3. 重新启用 RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 4. 创建简单策略：允许所有认证用户访问（避免递归）
-- 注意：这里不使用 auth.uid() 查询 user_roles 表，避免递归
CREATE POLICY "Allow all authenticated access user_roles"
ON user_roles FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 5. 允许匿名用户读取（如果需要）
CREATE POLICY "Allow anonymous read user_roles"
ON user_roles FOR SELECT
TO anon
USING (true);

-- 6. 验证策略
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- 7. 查看当前 user_roles 表中的数据
SELECT * FROM user_roles;
