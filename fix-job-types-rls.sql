-- 修复 job_types 表的 RLS 策略
-- 允许匿名用户读取工种列表（前端表单需要）

-- 1. 确保 RLS 已启用
ALTER TABLE job_types ENABLE ROW LEVEL SECURITY;

-- 2. 删除现有策略
DROP POLICY IF EXISTS "Allow authenticated read job_types" ON job_types;
DROP POLICY IF EXISTS "Allow admin manage job_types" ON job_types;
DROP POLICY IF EXISTS "Allow anonymous read job_types" ON job_types;

-- 3. 允许认证用户读取
CREATE POLICY "Allow authenticated read job_types"
ON job_types FOR SELECT
TO authenticated
USING (true);

-- 4. 允许管理员管理
CREATE POLICY "Allow admin manage job_types"
ON job_types FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

-- 5. 允许匿名用户读取（前端表单需要）
CREATE POLICY "Allow anonymous read job_types"
ON job_types FOR SELECT
TO anon
USING (true);

-- 同样修复 positions 表
ALTER TABLE positions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read positions" ON positions;
DROP POLICY IF EXISTS "Allow admin manage positions" ON positions;
DROP POLICY IF EXISTS "Allow anonymous read positions" ON positions;

CREATE POLICY "Allow authenticated read positions"
ON positions FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Allow admin manage positions"
ON positions FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    )
);

CREATE POLICY "Allow anonymous read positions"
ON positions FOR SELECT
TO anon
USING (true);
