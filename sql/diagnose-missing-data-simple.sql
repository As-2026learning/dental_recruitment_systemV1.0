-- ============================================
-- 数据消失问题诊断脚本（简化版）
-- 用于排查 VIVI 和 徐二 数据在招聘流程模块消失的原因
-- ============================================

-- 1. 检查 applications 表中 VIVI 和 徐二 的数据状态
SELECT 
    id,
    name,
    phone,
    status,
    interview_date,
    interview_time_slot,
    created_at,
    updated_at
FROM public.applications
WHERE name IN ('VIVI', '徐二')
ORDER BY name;

-- 2. 检查 recruitment_process 表中是否有对应记录
SELECT 
    rp.id,
    rp.application_id,
    rp.name,
    rp.phone,
    rp.source_status,
    rp.current_stage,
    rp.current_status,
    rp.interview_date,
    rp.interview_time_slot,
    rp.created_at,
    rp.updated_at
FROM public.recruitment_process rp
WHERE rp.name IN ('VIVI', '徐二')
ORDER BY rp.name;

-- 3. 检查 bookings 表中是否有对应预约记录
SELECT 
    b.id,
    b.application_id,
    a.name,
    b.booking_date,
    b.time_slot,
    b.status as booking_status,
    b.created_at
FROM public.bookings b
JOIN public.applications a ON b.application_id = a.id
WHERE a.name IN ('VIVI', '徐二')
ORDER BY a.name;

-- 4. 统计所有已处理但在招聘流程模块中缺失的数据
SELECT 
    a.id,
    a.name,
    a.phone,
    a.status,
    a.interview_date,
    CASE WHEN rp.id IS NULL THEN '缺失' ELSE '存在' END as in_recruitment_process
FROM public.applications a
LEFT JOIN public.recruitment_process rp ON a.id = rp.application_id
WHERE a.status = '已处理'
ORDER BY a.name;

-- 5. 输出诊断总结
SELECT '诊断完成' as message,
       (SELECT COUNT(*) FROM public.applications WHERE name IN ('VIVI', '徐二')) as app_count,
       (SELECT COUNT(*) FROM public.recruitment_process WHERE name IN ('VIVI', '徐二')) as rp_count,
       (SELECT COUNT(*) FROM public.bookings b JOIN public.applications a ON b.application_id = a.id WHERE a.name IN ('VIVI', '徐二')) as booking_count;
