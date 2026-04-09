-- ============================================
-- Supabase Auth 初始化脚本
-- 用于创建初始管理员用户和配置
-- ============================================

-- 1. 创建用户角色表（如果还不存在）
CREATE TABLE IF NOT EXISTS user_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('admin', 'operator', 'viewer')),
    name text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(user_id)
);

-- 2. 启用 RLS
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- 3. 创建 RLS 策略
DROP POLICY IF EXISTS "Allow authenticated read user_roles" ON user_roles;
CREATE POLICY "Allow authenticated read user_roles"
ON user_roles FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow admin manage user_roles" ON user_roles;
CREATE POLICY "Allow admin manage user_roles"
ON user_roles FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- 4. 创建函数：自动为新用户分配默认角色
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.user_roles (user_id, role, name)
    VALUES (new.id, 'operator', new.raw_user_meta_data->>'name');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 创建触发器
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 为所有业务表创建安全的 RLS 策略
-- ============================================

-- applications 表策略
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read applications" ON applications;
CREATE POLICY "Allow authenticated read applications"
ON applications FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated insert applications" ON applications;
CREATE POLICY "Allow authenticated insert applications"
ON applications FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated update applications" ON applications;
CREATE POLICY "Allow authenticated update applications"
ON applications FOR UPDATE
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated delete applications" ON applications;
CREATE POLICY "Allow authenticated delete applications"
ON applications FOR DELETE
TO authenticated
USING (true);

-- 允许匿名用户提交应聘（前端表单需要）
DROP POLICY IF EXISTS "Allow anonymous insert applications" ON applications;
CREATE POLICY "Allow anonymous insert applications"
ON applications FOR INSERT
TO anon
WITH CHECK (true);

-- bookings 表策略
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read bookings" ON bookings;
CREATE POLICY "Allow authenticated read bookings"
ON bookings FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow authenticated manage bookings" ON bookings;
CREATE POLICY "Allow authenticated manage bookings"
ON bookings FOR ALL
TO authenticated
USING (true);

-- 允许匿名用户创建预约
DROP POLICY IF EXISTS "Allow anonymous insert bookings" ON bookings;
CREATE POLICY "Allow anonymous insert bookings"
ON bookings FOR INSERT
TO anon
WITH CHECK (true);

-- recruitment_process 表策略
ALTER TABLE recruitment_process ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated full access recruitment_process" ON recruitment_process;
CREATE POLICY "Allow authenticated full access recruitment_process"
ON recruitment_process FOR ALL
TO authenticated
USING (true);

-- positions 表策略
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read positions" ON positions;
CREATE POLICY "Allow authenticated read positions"
ON positions FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow admin manage positions" ON positions;
CREATE POLICY "Allow admin manage positions"
ON positions FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- job_types 表策略
ALTER TABLE job_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read job_types" ON job_types;
CREATE POLICY "Allow authenticated read job_types"
ON job_types FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow admin manage job_types" ON job_types;
CREATE POLICY "Allow admin manage job_types"
ON job_types FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- system_config 表策略
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read system_config" ON system_config;
CREATE POLICY "Allow authenticated read system_config"
ON system_config FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Allow admin manage system_config" ON system_config;
CREATE POLICY "Allow admin manage system_config"
ON system_config FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- 允许匿名用户读取系统配置（前端需要）
DROP POLICY IF EXISTS "Allow anonymous read system_config" ON system_config;
CREATE POLICY "Allow anonymous read system_config"
ON system_config FOR SELECT
TO anon
USING (true);

-- ============================================
-- 创建存储用户自定义信息的函数
-- ============================================

-- 获取当前用户角色
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text AS $$
BEGIN
    RETURN (
        SELECT role FROM public.user_roles
        WHERE user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 获取当前用户信息
CREATE OR REPLACE FUNCTION public.get_user_info()
RETURNS TABLE (role text, name text) AS $$
BEGIN
    RETURN QUERY
    SELECT ur.role, ur.name
    FROM public.user_roles ur
    WHERE ur.user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
