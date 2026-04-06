-- ============================================
-- 面试日期同步功能数据库表结构
-- ============================================

-- 1. 为recruitment_process表添加面试日期字段
DO $$
BEGIN
    -- 检查并添加interview_date字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'recruitment_process' AND column_name = 'interview_date'
    ) THEN
        ALTER TABLE public.recruitment_process ADD COLUMN interview_date DATE;
        RAISE NOTICE '已添加interview_date字段到recruitment_process表';
    ELSE
        RAISE NOTICE 'interview_date字段已存在';
    END IF;

    -- 检查并添加interview_time_slot字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'recruitment_process' AND column_name = 'interview_time_slot'
    ) THEN
        ALTER TABLE public.recruitment_process ADD COLUMN interview_time_slot VARCHAR(50);
        RAISE NOTICE '已添加interview_time_slot字段到recruitment_process表';
    ELSE
        RAISE NOTICE 'interview_time_slot字段已存在';
    END IF;
END $$;

-- 2. 为applications表添加面试日期字段
DO $$
BEGIN
    -- 检查并添加interview_date字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'applications' AND column_name = 'interview_date'
    ) THEN
        ALTER TABLE public.applications ADD COLUMN interview_date DATE;
        RAISE NOTICE '已添加interview_date字段到applications表';
    ELSE
        RAISE NOTICE 'interview_date字段已存在';
    END IF;

    -- 检查并添加interview_time_slot字段
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'applications' AND column_name = 'interview_time_slot'
    ) THEN
        ALTER TABLE public.applications ADD COLUMN interview_time_slot VARCHAR(50);
        RAISE NOTICE '已添加interview_time_slot字段到applications表';
    ELSE
        RAISE NOTICE 'interview_time_slot字段已存在';
    END IF;
END $$;

-- 3. 创建面试日期变更历史记录表
CREATE TABLE IF NOT EXISTS public.interview_date_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
    candidate_name VARCHAR(100),
    candidate_phone VARCHAR(20),
    old_date DATE,
    old_time_slot VARCHAR(50),
    new_date DATE,
    new_time_slot VARCHAR(50),
    change_reason TEXT,
    changed_by VARCHAR(100) DEFAULT 'system',
    change_type VARCHAR(20) DEFAULT 'update', -- create, update, cancel
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 为历史记录表添加索引
CREATE INDEX IF NOT EXISTS idx_interview_history_app_id ON public.interview_date_history(application_id);
CREATE INDEX IF NOT EXISTS idx_interview_history_created_at ON public.interview_date_history(created_at);
CREATE INDEX IF NOT EXISTS idx_interview_history_change_type ON public.interview_date_history(change_type);

-- 4. 为recruitment_process表添加索引
CREATE INDEX IF NOT EXISTS idx_recruitment_process_interview_date ON public.recruitment_process(interview_date);

-- 5. 为applications表添加索引
CREATE INDEX IF NOT EXISTS idx_applications_interview_date ON public.applications(interview_date);

-- 6. 创建触发器函数：当bookings表变化时自动更新其他表
CREATE OR REPLACE FUNCTION public.sync_interview_date_from_bookings()
RETURNS TRIGGER AS $$
BEGIN
    -- 跳过已取消的预约
    IF NEW.status = 'cancelled' THEN
        -- 清空面试日期
        UPDATE public.recruitment_process 
        SET interview_date = NULL, interview_time_slot = NULL, updated_at = CURRENT_TIMESTAMP
        WHERE application_id = NEW.application_id;
        
        UPDATE public.applications 
        SET interview_date = NULL, interview_time_slot = NULL, updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.application_id;
        
        RETURN NEW;
    END IF;

    -- 同步到recruitment_process表
    UPDATE public.recruitment_process 
    SET interview_date = NEW.booking_date, 
        interview_time_slot = NEW.time_slot, 
        updated_at = CURRENT_TIMESTAMP
    WHERE application_id = NEW.application_id;

    -- 同步到applications表
    UPDATE public.applications 
    SET interview_date = NEW.booking_date, 
        interview_time_slot = NEW.time_slot, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.application_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 删除已存在的触发器（如果存在）
DROP TRIGGER IF EXISTS trg_sync_interview_date ON public.bookings;

-- 创建触发器
CREATE TRIGGER trg_sync_interview_date
    AFTER INSERT OR UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_interview_date_from_bookings();

-- 7. 为历史记录表启用RLS
ALTER TABLE public.interview_date_history ENABLE ROW LEVEL SECURITY;

-- 创建访问策略
CREATE POLICY "Allow all access to interview_date_history" 
ON public.interview_date_history FOR ALL USING (true);

-- 8. 为历史记录表添加触发器（自动更新updated_at）
CREATE TRIGGER update_interview_history_updated_at
    BEFORE UPDATE ON public.interview_date_history
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 9. 创建视图：候选人面试信息汇总
CREATE OR REPLACE VIEW public.candidate_interview_summary AS
SELECT 
    a.id AS application_id,
    a.name AS candidate_name,
    a.phone AS candidate_phone,
    a.position,
    a.job_type,
    a.interview_date,
    a.interview_time_slot,
    b.booking_date AS booking_date,
    b.time_slot AS booking_time_slot,
    b.status AS booking_status,
    rp.current_stage,
    rp.current_status,
    CASE 
        WHEN b.status = 'cancelled' THEN '已取消'
        WHEN b.booking_date IS NOT NULL THEN '已预约'
        WHEN a.interview_date IS NOT NULL THEN '已安排'
        ELSE '未安排'
    END AS interview_status
FROM public.applications a
LEFT JOIN public.bookings b ON a.id = b.application_id AND b.status != 'cancelled'
LEFT JOIN public.recruitment_process rp ON a.id = rp.application_id;

-- 10. 初始化数据：将现有bookings数据同步到其他表
DO $$
DECLARE
    booking_record RECORD;
    update_count INTEGER := 0;
BEGIN
    FOR booking_record IN 
        SELECT DISTINCT ON (application_id) 
            application_id, booking_date, time_slot, status
        FROM public.bookings 
        WHERE status != 'cancelled'
        ORDER BY application_id, created_at DESC
    LOOP
        -- 更新recruitment_process表
        UPDATE public.recruitment_process 
        SET interview_date = booking_record.booking_date, 
            interview_time_slot = booking_record.time_slot,
            updated_at = CURRENT_TIMESTAMP
        WHERE application_id = booking_record.application_id;

        -- 更新applications表
        UPDATE public.applications 
        SET interview_date = booking_record.booking_date, 
            interview_time_slot = booking_record.time_slot,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = booking_record.application_id;

        update_count := update_count + 1;
    END LOOP;

    RAISE NOTICE '已同步 % 条面试日期数据', update_count;
END $$;

-- 输出完成信息
SELECT '面试日期同步功能数据库设置完成' AS message;
