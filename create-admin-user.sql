-- ============================================
-- 创建初始管理员用户
-- 在 Supabase SQL Editor 中执行
-- ============================================

-- 创建管理员用户（请修改邮箱和密码）
-- 注意：密码需要至少6位字符

-- 方法：使用 Supabase Auth API 创建用户
-- 由于 SQL 无法直接创建 auth 用户，请在 Supabase 控制台操作：

/*
步骤：

1. 登录 Supabase 控制台
2. 进入 Authentication → Users
3. 点击 "New User"
4. 输入邮箱和密码
5. 创建用户后，执行下面的 SQL 设置角色

或者使用 Supabase Dashboard 的 SQL Editor 执行：
*/

-- 为指定用户设置管理员角色（将 'user-uuid-here' 替换为实际的用户 UUID）
-- INSERT INTO public.user_roles (user_id, role, name)
-- VALUES ('user-uuid-here', 'admin', '系统管理员');

-- ============================================
-- 创建测试数据（可选）
-- ============================================

-- 如果您想快速测试，可以先禁用 RLS 进行测试
-- 测试完成后再启用 RLS

-- 临时禁用 RLS（仅用于测试）
-- ALTER TABLE applications DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE recruitment_process DISABLE ROW LEVEL SECURITY;

-- 重新启用 RLS（测试完成后执行）
-- ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE recruitment_process ENABLE ROW LEVEL SECURITY;
