-- 添加缺失的字段到 recruitment_process 表

-- 添加录用相关字段
ALTER TABLE recruitment_process 
ADD COLUMN IF NOT EXISTS job_title VARCHAR(100),
ADD COLUMN IF NOT EXISTS accept_offer VARCHAR(20),
ADD COLUMN IF NOT EXISTS offer_reject_reason TEXT;

-- 确认字段已添加
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'recruitment_process' 
AND column_name IN ('job_title', 'accept_offer', 'offer_reject_reason');
