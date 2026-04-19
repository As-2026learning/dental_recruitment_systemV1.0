-- ========================================================
-- Supabase 安全加固脚本 - 简化版
-- ========================================================

-- 1. 启用 user_roles 表的 RLS
ALTER TABLE IF EXISTS user_roles ENABLE ROW LEVEL SECURITY;

-- 2. 删除已存在的策略
DROP POLICY IF EXISTS "Users can view their own profile" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_roles;
DROP POLICY IF EXISTS "Admin can access all users" ON user_roles;

-- 3. 创建辅助函数检查用户角色（使用 SECURITY DEFINER 绕过 RLS）
-- 避免在策略中直接查询 user_roles 表导致无限递归
DROP FUNCTION IF EXISTS is_admin;
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() AND role = 'admin'
  );
END $$;

GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- 4. 创建用户权限策略
-- 用户只能查看自己的账户
CREATE POLICY "Users can view their own profile" 
  ON user_roles FOR SELECT 
  USING (auth.uid() = user_id);

-- 用户只能更新自己的账户
CREATE POLICY "Users can update their own profile" 
  ON user_roles FOR UPDATE 
  USING (auth.uid() = user_id);

-- 管理员可以访问所有用户数据（使用函数避免递归）
CREATE POLICY "Admin can access all users" 
  ON user_roles FOR ALL 
  USING (is_admin());

-- 5. 创建 is_operator 辅助函数
DROP FUNCTION IF EXISTS is_operator;
CREATE OR REPLACE FUNCTION is_operator()
RETURNS BOOLEAN
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() AND role IN ('admin', 'operator')
  );
END $$;

GRANT EXECUTE ON FUNCTION is_operator() TO authenticated;

-- 6. 如果 positions 表存在，启用 RLS 并创建策略
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'positions') THEN
    EXECUTE 'ALTER TABLE positions ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Public can view positions" ON positions';
    EXECUTE 'DROP POLICY IF EXISTS "Admin can manage positions" ON positions';
    EXECUTE 'DROP POLICY IF EXISTS "Operator can create positions" ON positions';
    
    EXECUTE 'CREATE POLICY "Public can view positions" ON positions FOR SELECT USING (true)';
    EXECUTE 'CREATE POLICY "Admin can manage positions" ON positions FOR ALL USING (is_admin())';
    EXECUTE 'CREATE POLICY "Operator can create positions" ON positions FOR INSERT WITH CHECK (is_operator())';
  END IF;
END $$;

-- 7. 如果 reservations 表存在，启用 RLS 并创建策略
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reservations') THEN
    EXECUTE 'ALTER TABLE reservations ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Admin can manage reservations" ON reservations';
    EXECUTE 'DROP POLICY IF EXISTS "Operator can manage reservations" ON reservations';
    
    EXECUTE 'CREATE POLICY "Admin can manage reservations" ON reservations FOR ALL USING (is_admin())';
    EXECUTE 'CREATE POLICY "Operator can manage reservations" ON reservations FOR ALL USING (is_operator())';
  END IF;
END $$;

-- 8. 如果 templates 表存在，启用 RLS 并创建策略
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'templates') THEN
    EXECUTE 'ALTER TABLE templates ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Admin can manage templates" ON templates';
    EXECUTE 'DROP POLICY IF EXISTS "Operator can view templates" ON templates';
    
    EXECUTE 'CREATE POLICY "Admin can manage templates" ON templates FOR ALL USING (is_admin())';
    EXECUTE 'CREATE POLICY "Operator can view templates" ON templates FOR SELECT USING (is_operator())';
  END IF;
END $$;

-- 9. 如果 candidates 表存在，启用 RLS 并创建策略
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'candidates') THEN
    EXECUTE 'ALTER TABLE candidates ENABLE ROW LEVEL SECURITY';
    EXECUTE 'DROP POLICY IF EXISTS "Admin can access all candidates" ON candidates';
    EXECUTE 'DROP POLICY IF EXISTS "Operator can view candidates" ON candidates';
    
    EXECUTE 'CREATE POLICY "Admin can access all candidates" ON candidates FOR ALL USING (is_admin())';
    EXECUTE 'CREATE POLICY "Operator can view candidates" ON candidates FOR SELECT USING (is_operator())';
  END IF;
END $$;

-- 10. 创建 get_user_role RPC 函数用于登录时获取角色（绕过RLS）
-- 使用 TEXT 类型参数以兼容 JavaScript 字符串传入
DROP FUNCTION IF EXISTS get_user_role;
DROP FUNCTION IF EXISTS get_user_role(TEXT);
CREATE OR REPLACE FUNCTION get_user_role(user_id_input TEXT)
RETURNS JSON
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (
    SELECT json_build_object(
      'role', role,
      'name', name
    )
    FROM user_roles
    WHERE user_id = user_id_input::UUID
  );
END $$;

-- 授予执行权限
GRANT EXECUTE ON FUNCTION get_user_role(TEXT) TO authenticated;

-- ========================================================
-- 执行完毕！
-- ========================================================