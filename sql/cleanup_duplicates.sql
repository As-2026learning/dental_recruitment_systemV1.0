-- ============================================
-- 招聘流程重复数据清理脚本
-- 针对 application_id 重复的情况
-- ============================================

-- 步骤1：查看重复数据详情
SELECT 
    application_id,
    name,
    COUNT(*) as count,
    ARRAY_AGG(id ORDER BY updated_at DESC) as ids,
    ARRAY_AGG(current_stage ORDER BY updated_at DESC) as stages
FROM recruitment_process
WHERE application_id IS NOT NULL
GROUP BY application_id, name
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 步骤2：创建临时表保存要保留的记录ID（每组的最新记录）
CREATE TEMP TABLE records_to_keep AS
SELECT DISTINCT ON (application_id)
    id,
    application_id,
    name,
    current_stage,
    current_status,
    updated_at
FROM recruitment_process
WHERE application_id IS NOT NULL
ORDER BY application_id, updated_at DESC;

-- 步骤3：查看要保留的记录
SELECT * FROM records_to_keep;

-- 步骤4：查看要删除的记录
SELECT 
    rp.id,
    rp.application_id,
    rp.name,
    rp.current_stage,
    rp.current_status
FROM recruitment_process rp
LEFT JOIN records_to_keep rtk ON rp.id = rtk.id
WHERE rp.application_id IS NOT NULL
AND rtk.id IS NULL;

-- 步骤5：执行删除（谨慎操作！先确认上面的查询结果）
-- DELETE FROM recruitment_process
-- WHERE id IN (
--     SELECT rp.id
--     FROM recruitment_process rp
--     LEFT JOIN records_to_keep rtk ON rp.id = rtk.id
--     WHERE rp.application_id IS NOT NULL
--     AND rtk.id IS NULL
-- );

-- 步骤6：验证删除结果
-- SELECT COUNT(*) as remaining_count 
-- FROM recruitment_process 
-- WHERE application_id IS NOT NULL;

-- 步骤7：清理临时表
-- DROP TABLE records_to_keep;
