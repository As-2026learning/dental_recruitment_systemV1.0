-- 检查 recruitment_process 表的现有字段
SELECT 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'recruitment_process' 
ORDER BY ordinal_position;

-- 如果上述查询结果显示缺少字段，请执行以下语句添加：

-- 添加录用相关字段（如果不存在）
DO $$
BEGIN
    -- 添加 job_title 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'recruitment_process' AND column_name = 'job_title') THEN
        ALTER TABLE recruitment_process ADD COLUMN job_title VARCHAR(100);
        RAISE NOTICE 'Added column: job_title';
    END IF;
    
    -- 添加 accept_offer 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'recruitment_process' AND column_name = 'accept_offer') THEN
        ALTER TABLE recruitment_process ADD COLUMN accept_offer VARCHAR(20);
        RAISE NOTICE 'Added column: accept_offer';
    END IF;
    
    -- 添加 offer_reject_reason 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'recruitment_process' AND column_name = 'offer_reject_reason') THEN
        ALTER TABLE recruitment_process ADD COLUMN offer_reject_reason TEXT;
        RAISE NOTICE 'Added column: offer_reject_reason';
    END IF;
END $$;

-- 验证字段是否已添加
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'recruitment_process' 
AND column_name IN ('job_title', 'accept_offer', 'offer_reject_reason');
