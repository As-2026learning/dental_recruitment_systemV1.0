-- ========================================================
-- Supabase 安全加固脚本
-- 执行此脚本以修复 "Table publicly accessible" 问题
-- ========================================================

-- 1. 检查并启用存在的表的行级安全（RLS）
DO $$
DECLARE
    table_name TEXT;
BEGIN
    -- 检查并启用 user_roles 表的 RLS
    SELECT tablename INTO table_name FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_roles';
    IF FOUND THEN
        EXECUTE 'ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已启用 user_roles 表的 RLS';
    END IF;

    -- 检查并启用 positions 表的 RLS
    SELECT tablename INTO table_name FROM pg_tables WHERE schemaname = 'public' AND tablename = 'positions';
    IF FOUND THEN
        EXECUTE 'ALTER TABLE positions ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已启用 positions 表的 RLS';
    END IF;

    -- 检查并启用 candidates 表的 RLS
    SELECT tablename INTO table_name FROM pg_tables WHERE schemaname = 'public' AND tablename = 'candidates';
    IF FOUND THEN
        EXECUTE 'ALTER TABLE candidates ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已启用 candidates 表的 RLS';
    END IF;

    -- 检查并启用 reservations 表的 RLS
    SELECT tablename INTO table_name FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reservations';
    IF FOUND THEN
        EXECUTE 'ALTER TABLE reservations ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已启用 reservations 表的 RLS';
    END IF;

    -- 检查并启用 templates 表的 RLS
    SELECT tablename INTO table_name FROM pg_tables WHERE schemaname = 'public' AND tablename = 'templates';
    IF FOUND THEN
        EXECUTE 'ALTER TABLE templates ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已启用 templates 表的 RLS';
    END IF;

    -- 检查并启用其他可能存在的表
    SELECT tablename INTO table_name FROM pg_tables WHERE schemaname = 'public' AND tablename = 'interviews';
    IF FOUND THEN
        EXECUTE 'ALTER TABLE interviews ENABLE ROW LEVEL SECURITY';
        RAISE NOTICE '已启用 interviews 表的 RLS';
    END IF;
END $$;

-- 2. 创建数据库角色（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_role') THEN
        CREATE ROLE admin_role;
        RAISE NOTICE '已创建 admin_role 角色';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'operator_role') THEN
        CREATE ROLE operator_role;
        RAISE NOTICE '已创建 operator_role 角色';
    END IF;
END $$;

-- 3. 为 user_roles 表创建RLS策略
-- 删除已存在的策略
DROP POLICY IF EXISTS "Users can view their own profile" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_roles;
DROP POLICY IF EXISTS "Admin can access all users" ON user_roles;

-- 用户只能查看自己的账户
CREATE POLICY "Users can view their own profile" 
  ON user_roles FOR SELECT 
  USING (auth.uid() = user_id);

-- 用户只能更新自己的账户
CREATE POLICY "Users can update their own profile" 
  ON user_roles FOR UPDATE 
  USING (auth.uid() = user_id);

-- 管理员可以访问所有用户数据
CREATE POLICY "Admin can access all users" 
  ON user_roles FOR ALL 
  USING (EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = auth.uid() AND role = 'admin'
  ));

-- 4. 为 positions 表创建RLS策略（如果存在）
DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'positions') INTO table_exists;
    IF table_exists THEN
        DROP POLICY IF EXISTS "Public can view positions" ON positions;
        DROP POLICY IF EXISTS "Admin can manage positions" ON positions;
        DROP POLICY IF EXISTS "Operator can create positions" ON positions;

        CREATE POLICY "Public can view positions" 
          ON positions FOR SELECT 
          USING (true);

        CREATE POLICY "Admin can manage positions" 
          ON positions FOR ALL 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role = 'admin'
          ));

        CREATE POLICY "Operator can create positions" 
          ON positions FOR INSERT 
          WITH CHECK (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role IN ('admin', 'operator')
          ));
        RAISE NOTICE '已为 positions 表创建 RLS 策略';
    END IF;
END $$;

-- 5. 为 candidates 表创建RLS策略（如果存在）
DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'candidates') INTO table_exists;
    IF table_exists THEN
        DROP POLICY IF EXISTS "Admin can access all candidates" ON candidates;
        DROP POLICY IF EXISTS "Operator can view and create candidates" ON candidates;
        DROP POLICY IF EXISTS "Operator can insert candidates" ON candidates;

        CREATE POLICY "Admin can access all candidates" 
          ON candidates FOR ALL 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role = 'admin'
          ));

        CREATE POLICY "Operator can view and create candidates" 
          ON candidates FOR SELECT 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role IN ('admin', 'operator')
          ));

        CREATE POLICY "Operator can insert candidates" 
          ON candidates FOR INSERT 
          WITH CHECK (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role IN ('admin', 'operator')
          ));
        RAISE NOTICE '已为 candidates 表创建 RLS 策略';
    END IF;
END $$;

-- 6. 为 reservations 表创建RLS策略（如果存在）
DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reservations') INTO table_exists;
    IF table_exists THEN
        DROP POLICY IF EXISTS "Admin can manage reservations" ON reservations;
        DROP POLICY IF EXISTS "Operator can manage reservations" ON reservations;

        CREATE POLICY "Admin can manage reservations" 
          ON reservations FOR ALL 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role = 'admin'
          ));

        CREATE POLICY "Operator can manage reservations" 
          ON reservations FOR ALL 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role IN ('admin', 'operator')
          ));
        RAISE NOTICE '已为 reservations 表创建 RLS 策略';
    END IF;
END $$;

-- 7. 为 templates 表创建RLS策略（如果存在）
DO $$
DECLARE
    table_exists BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'templates') INTO table_exists;
    IF table_exists THEN
        DROP POLICY IF EXISTS "Admin can manage templates" ON templates;
        DROP POLICY IF EXISTS "Operator can view templates" ON templates;

        CREATE POLICY "Admin can manage templates" 
          ON templates FOR ALL 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role = 'admin'
          ));

        CREATE POLICY "Operator can view templates" 
          ON templates FOR SELECT 
          USING (EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() AND role IN ('admin', 'operator')
          ));
        RAISE NOTICE '已为 templates 表创建 RLS 策略';
    END IF;
END $$;

-- 8. 创建存储过程用于安全的用户创建（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'create_user_with_role') THEN
        CREATE OR REPLACE FUNCTION create_user_with_role(
          p_email TEXT, 
          p_password TEXT, 
          p_name TEXT, 
          p_role TEXT DEFAULT 'operator'
        ) 
        RETURNS JSON 
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $$
        DECLARE
          v_user_id UUID;
        BEGIN
          INSERT INTO auth.users (email, encrypted_password, email_confirmed_at)
          VALUES (p_email, crypt(p_password, gen_salt('bf')), NOW())
          RETURNING id INTO v_user_id;
          
          INSERT INTO user_roles (user_id, name, role)
          VALUES (v_user_id, p_name, p_role);
          
          RETURN json_build_object('user_id', v_user_id, 'status', 'success');
        EXCEPTION
          WHEN OTHERS THEN
            RETURN json_build_object('status', 'error', 'message', SQLERRM);
        END $$;
        RAISE NOTICE '已创建 create_user_with_role 函数';
    END IF;
END $$;

-- 9. 授予执行权限
GRANT EXECUTE ON FUNCTION create_user_with_role(TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- ========================================================
-- 执行完毕！
-- 请在Supabase控制台中：
-- 1. 验证所有表的RLS已启用
-- 2. 测试用户权限是否正确
-- ========================================================