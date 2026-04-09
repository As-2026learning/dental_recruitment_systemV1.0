-- ============================================
-- 修复 user_roles 表的 RLS 策略 - 简化安全版本
-- ============================================

-- 1. 禁用 RLS（临时）
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;

-- 2. 删除所有现有策略
DROP POLICY IF EXISTS "Allow authenticated read user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow admin manage user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow users read own role" ON user_roles;
DROP POLICY IF EXISTS "Allow authenticated full access user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow all access user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow anonymous read user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow all authenticated access user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow admin read all roles" ON user_roles;
DROP POLICY IF EXISTS "Allow admin manage all roles" ON user_roles;
DROP POLICY IF EXISTS "Allow users update own role" ON user_roles;

-- 3. 重新启用 RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 4. 允许认证用户读取自己的角色（最安全的方式）
CREATE POLICY "Allow users read own role"
ON user_roles FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 5. 允许认证用户更新自己的角色
CREATE POLICY "Allow users update own role"
ON user_roles FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- 6. 允许认证用户插入自己的角色（首次创建）
CREATE POLICY "Allow users insert own role"
ON user_roles FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- 7. 验证策略
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- 8. 查看当前 user_roles 表中的数据
SELECT * FROM user_roles;
