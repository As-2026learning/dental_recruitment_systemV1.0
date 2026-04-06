-- 检查 VIVI 和 徐二在 recruitment_process 表中的详细状态
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

-- 检查 applications 表中的状态
SELECT 
    a.id,
    a.name,
    a.phone,
    a.status,
    a.interview_date,
    a.interview_time_slot
FROM public.applications a
WHERE a.name IN ('VIVI', '徐二')
ORDER BY a.name;
