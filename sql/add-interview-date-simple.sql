-- ============================================
-- 简化版：添加面试日期字段
-- 请逐条执行这些SQL语句
-- ============================================

-- 1. 为 recruitment_process 表添加面试日期字段
ALTER TABLE public.recruitment_process 
ADD COLUMN IF NOT EXISTS interview_date DATE,
ADD COLUMN IF NOT EXISTS interview_time_slot VARCHAR(50);

-- 2. 为 applications 表添加面试日期字段
ALTER TABLE public.applications 
ADD COLUMN IF NOT EXISTS interview_date DATE,
ADD COLUMN IF NOT EXISTS interview_time_slot VARCHAR(50);

-- 3. 创建面试日期变更历史记录表
CREATE TABLE IF NOT EXISTS public.interview_date_history (
    id SERIAL PRIMARY KEY,
    application_id INTEGER REFERENCES public.applications(id) ON DELETE CASCADE,
    candidate_name VARCHAR(100),
    candidate_phone VARCHAR(20),
    old_date DATE,
    old_time_slot VARCHAR(50),
    new_date DATE,
    new_time_slot VARCHAR(50),
    change_reason TEXT,
    changed_by VARCHAR(100) DEFAULT 'system',
    change_type VARCHAR(20) DEFAULT 'update',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. 添加索引
CREATE INDEX IF NOT EXISTS idx_interview_history_app_id ON public.interview_date_history(application_id);
CREATE INDEX IF NOT EXISTS idx_rp_interview_date ON public.recruitment_process(interview_date);
CREATE INDEX IF NOT EXISTS idx_app_interview_date ON public.applications(interview_date);

-- 5. 创建触发器函数：自动同步面试日期
CREATE OR REPLACE FUNCTION public.sync_interview_date_from_bookings()
RETURNS TRIGGER AS $$
BEGIN
    -- 跳过已取消的预约
    IF NEW.status = 'cancelled' THEN
        UPDATE public.recruitment_process 
        SET interview_date = NULL, interview_time_slot = NULL, updated_at = CURRENT_TIMESTAMP
        WHERE application_id = NEW.application_id;
        
        UPDATE public.applications 
        SET interview_date = NULL, interview_time_slot = NULL, updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.application_id;
        
        RETURN NEW;
    END IF;

    -- 同步到 recruitment_process 表
    UPDATE public.recruitment_process 
    SET interview_date = NEW.booking_date, 
        interview_time_slot = NEW.time_slot, 
        updated_at = CURRENT_TIMESTAMP
    WHERE application_id = NEW.application_id;

    -- 同步到 applications 表
    UPDATE public.applications 
    SET interview_date = NEW.booking_date, 
        interview_time_slot = NEW.time_slot, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.application_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. 删除已存在的触发器（如果存在）
DROP TRIGGER IF EXISTS trg_sync_interview_date ON public.bookings;

-- 7. 创建触发器
CREATE TRIGGER trg_sync_interview_date
    AFTER INSERT OR UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_interview_date_from_bookings();

-- 8. 为历史记录表启用RLS
ALTER TABLE public.interview_date_history ENABLE ROW LEVEL SECURITY;

-- 9. 创建访问策略
DROP POLICY IF EXISTS "Allow all access to interview_date_history" ON public.interview_date_history;
CREATE POLICY "Allow all access to interview_date_history" 
ON public.interview_date_history FOR ALL USING (true);

-- 10. 初始化数据：将现有bookings数据同步到其他表
UPDATE public.recruitment_process rp
SET 
    interview_date = b.booking_date,
    interview_time_slot = b.time_slot,
    updated_at = CURRENT_TIMESTAMP
FROM (
    SELECT DISTINCT ON (application_id) 
        application_id, booking_date, time_slot
    FROM public.bookings 
    WHERE status != 'cancelled'
    ORDER BY application_id, created_at DESC
) b
WHERE rp.application_id = b.application_id;

UPDATE public.applications a
SET 
    interview_date = b.booking_date,
    interview_time_slot = b.time_slot,
    updated_at = CURRENT_TIMESTAMP
FROM (
    SELECT DISTINCT ON (application_id) 
        application_id, booking_date, time_slot
    FROM public.bookings 
    WHERE status != 'cancelled'
    ORDER BY application_id, created_at DESC
) b
WHERE a.id = b.application_id;

-- 完成
SELECT '面试日期字段添加完成' AS message;
