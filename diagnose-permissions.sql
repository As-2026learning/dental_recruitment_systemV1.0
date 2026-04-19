-- ============================================
-- 诊断权限问题
-- ============================================

-- 1. 检查表是否存在
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'template_field_mappings',
    'field_configs',
    'field_options',
    'templates',
    'positions',
    'job_types',
    'time_slots',
    'applications',
    'bookings'
)
ORDER BY table_name;

-- 2. 检查表的RLS状态
SELECT 
    relname as table_name,
    relrowsecurity as rls_enabled
FROM pg_class
WHERE relname IN (
    'template_field_mappings',
    'field_configs',
    'field_options',
    'templates',
    'positions',
    'job_types',
    'time_slots',
    'applications',
    'bookings'
)
AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY relname;

-- 3. 检查当前策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN (
    'template_field_mappings',
    'field_configs',
    'field_options',
    'templates',
    'positions',
    'job_types',
    'time_slots',
    'applications',
    'bookings'
)
ORDER BY tablename, policyname;

-- 4. 检查表中是否有数据
SELECT 'templates' as table_name, COUNT(*) as row_count FROM templates
UNION ALL
SELECT 'field_configs', COUNT(*) FROM field_configs
UNION ALL
SELECT 'field_options', COUNT(*) FROM field_options
UNION ALL
SELECT 'template_field_mappings', COUNT(*) FROM template_field_mappings
UNION ALL
SELECT 'positions', COUNT(*) FROM positions
UNION ALL
SELECT 'job_types', COUNT(*) FROM job_types
UNION ALL
SELECT 'time_slots', COUNT(*) FROM time_slots;
