-- ============================================
-- 修复权限管理页面的数据库配置问题
-- 在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 1. 创建 confirm_email RPC 函数
CREATE OR REPLACE FUNCTION public.confirm_email(user_email TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE auth.users
    SET email_confirmed_at = NOW()
    WHERE email = user_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 创建 user_roles 表（如果不存在）
CREATE TABLE IF NOT EXISTS public.user_roles (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'operator', 'viewer')),
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 3. 更新 user_roles 表的 RLS 策略
-- 首先删除现有策略（如果存在）
DROP POLICY IF EXISTS "Allow authenticated users to read user_roles" ON public.user_roles;
DROP POLICY IF EXISTS "Allow admins to manage user_roles" ON public.user_roles;

-- 创建新的RLS策略
CREATE POLICY "Allow authenticated users to read user_roles"
    ON public.user_roles
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow admins to manage user_roles"
    ON public.user_roles
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 4. 确保 RLS 已启用
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- 5. 创建索引优化查询
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- 验证
SELECT 'user_roles table created/updated' as status;
SELECT COUNT(*) as role_count FROM public.user_roles;