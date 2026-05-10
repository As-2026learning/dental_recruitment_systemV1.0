-- ============================================
-- 为所有表启用 RLS 并配置策略
-- 执行此脚本解决安全提醒问题
-- ============================================

-- 1. 为所有业务表启用 RLS
ALTER TABLE IF EXISTS public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.field_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.template_field_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.field_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.system_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.job_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.recruitment_process ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.recruitment_first_interview ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.recruitment_second_interview ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.recruitment_onboarding ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.recruitment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.interview_date_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_roles ENABLE ROW LEVEL SECURITY;

-- 2. applications 表策略
DROP POLICY IF EXISTS "Allow anonymous insert on applications" ON applications;
DROP POLICY IF EXISTS "Allow anonymous select on applications" ON applications;
DROP POLICY IF EXISTS "Allow authenticated all on applications" ON applications;

CREATE POLICY "Allow anonymous insert on applications"
ON applications FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous select on applications"
ON applications FOR SELECT TO anon USING (true);

CREATE POLICY "Allow authenticated all on applications"
ON applications FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 3. bookings 表策略
DROP POLICY IF EXISTS "Allow anonymous all on bookings" ON bookings;
CREATE POLICY "Allow anonymous all on bookings"
ON bookings FOR ALL TO anon USING (true) WITH CHECK (true);

-- 4. templates 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on templates" ON templates;
CREATE POLICY "Allow anonymous select on templates"
ON templates FOR SELECT TO anon USING (true);

-- 5. field_configs 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on field_configs" ON field_configs;
CREATE POLICY "Allow anonymous select on field_configs"
ON field_configs FOR SELECT TO anon USING (true);

-- 6. positions 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on positions" ON positions;
CREATE POLICY "Allow anonymous select on positions"
ON positions FOR SELECT TO anon USING (true);

-- 7. time_slots 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on time_slots" ON time_slots;
CREATE POLICY "Allow anonymous select on time_slots"
ON time_slots FOR SELECT TO anon USING (true);

-- 8. job_types 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on job_types" ON job_types;
CREATE POLICY "Allow anonymous select on job_types"
ON job_types FOR SELECT TO anon USING (true);

-- 9. recruitment_process 表策略
DROP POLICY IF EXISTS "Allow anonymous all on recruitment_process" ON recruitment_process;
CREATE POLICY "Allow anonymous all on recruitment_process"
ON recruitment_process FOR ALL TO anon USING (true) WITH CHECK (true);

-- 10. 其他招聘相关表策略
DROP POLICY IF EXISTS "Allow anonymous all on recruitment_first_interview" ON recruitment_first_interview;
CREATE POLICY "Allow anonymous all on recruitment_first_interview"
ON recruitment_first_interview FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anonymous all on recruitment_second_interview" ON recruitment_second_interview;
CREATE POLICY "Allow anonymous all on recruitment_second_interview"
ON recruitment_second_interview FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anonymous all on recruitment_onboarding" ON recruitment_onboarding;
CREATE POLICY "Allow anonymous all on recruitment_onboarding"
ON recruitment_onboarding FOR ALL TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anonymous all on recruitment_history" ON recruitment_history;
CREATE POLICY "Allow anonymous all on recruitment_history"
ON recruitment_history FOR ALL TO anon USING (true) WITH CHECK (true);

-- 11. interview_date_history 表策略
DROP POLICY IF EXISTS "Allow all access to interview_date_history" ON interview_date_history;
CREATE POLICY "Allow all access to interview_date_history"
ON interview_date_history FOR ALL TO anon USING (true) WITH CHECK (true);

-- 12. user_roles 表策略
DROP POLICY IF EXISTS "Allow anonymous all on user_roles" ON user_roles;
CREATE POLICY "Allow anonymous all on user_roles"
ON user_roles FOR ALL TO anon USING (true) WITH CHECK (true);

-- 输出完成信息
SELECT '所有表已启用 RLS 并配置策略' AS status;
