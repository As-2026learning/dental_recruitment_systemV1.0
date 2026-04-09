-- ============================================
-- 修复 user_roles 表的 RLS 策略 - 安全版本
-- 解决无限递归问题，同时保证安全性
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

-- 3. 重新启用 RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 4. 允许认证用户读取自己的角色（使用 auth.uid() 直接比较，避免递归）
CREATE POLICY "Allow users read own role"
ON user_roles FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 5. 允许认证用户更新自己的角色（如果需要）
CREATE POLICY "Allow users update own role"
ON user_roles FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- 6. 允许管理员管理所有角色（使用 SECURITY DEFINER 函数避免递归）
-- 创建辅助函数来检查管理员权限
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
    -- 直接查询 auth.uid()，不查询 user_roles 表
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 允许管理员读取所有角色
CREATE POLICY "Allow admin read all roles"
ON user_roles FOR SELECT
TO authenticated
USING (public.is_admin());

-- 8. 允许管理员管理所有角色
CREATE POLICY "Allow admin manage all roles"
ON user_roles FOR ALL
TO authenticated
USING (public.is_admin());

-- 9. 验证策略
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'user_roles';

-- 10. 查看当前 user_roles 表中的数据
SELECT * FROM user_roles;
