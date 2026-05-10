-- ============================================
-- 为所有表启用 RLS 并配置策略（最终版）
-- ============================================

-- 1. 为核心表启用 RLS（这些表一定存在）
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.time_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recruitment_process ENABLE ROW LEVEL SECURITY;

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

-- 5. positions 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on positions" ON positions;
CREATE POLICY "Allow anonymous select on positions"
ON positions FOR SELECT TO anon USING (true);

-- 6. time_slots 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on time_slots" ON time_slots;
CREATE POLICY "Allow anonymous select on time_slots"
ON time_slots FOR SELECT TO anon USING (true);

-- 7. job_types 表策略（只读）
DROP POLICY IF EXISTS "Allow anonymous select on job_types" ON job_types;
CREATE POLICY "Allow anonymous select on job_types"
ON job_types FOR SELECT TO anon USING (true);

-- 8. recruitment_process 表策略
DROP POLICY IF EXISTS "Allow anonymous all on recruitment_process" ON recruitment_process;
CREATE POLICY "Allow anonymous all on recruitment_process"
ON recruitment_process FOR ALL TO anon USING (true) WITH CHECK (true);

-- 输出完成信息
SELECT 'RLS 配置完成' AS status;
