-- ============================================
-- 修复 user_roles 表的 RLS 策略
-- 确保认证用户可以读取自己的角色信息
-- ============================================

-- 1. 确保 RLS 已启用
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 2. 删除所有现有策略
DROP POLICY IF EXISTS "Allow authenticated read user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow admin manage user_roles" ON user_roles;
DROP POLICY IF EXISTS "Allow users read own role" ON user_roles;
DROP POLICY IF EXISTS "Allow authenticated full access user_roles" ON user_roles;

-- 3. 允许认证用户读取所有角色信息（简化权限）
CREATE POLICY "Allow authenticated read user_roles"
ON user_roles FOR SELECT
TO authenticated
USING (true);

-- 4. 允许管理员管理角色
CREATE POLICY "Allow admin manage user_roles"
ON user_roles FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- 5. 验证策略
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- 6. 查看当前 user_roles 表中的数据
SELECT * FROM user_roles;
