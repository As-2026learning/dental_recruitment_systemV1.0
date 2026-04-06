-- 修复 work_experience 字段数据
-- 将错误存储的"3-5年"等年限数据清空，保留真正的详细工作经历

-- 查看当前 work_experience 字段的数据分布
SELECT 
    work_experience,
    COUNT(*) as count
FROM recruitment_process
WHERE work_experience IS NOT NULL 
  AND work_experience != ''
GROUP BY work_experience;

-- 更新：将看起来像年限的数据（如"3-5年"、"5年以上"等）清空
UPDATE recruitment_process
SET work_experience = NULL
WHERE work_experience ~ '^[0-9]+[-+]?[0-9]*年'  -- 匹配 "3-5年"、"5年"、"5年以上" 等模式
   OR work_experience ~ '^[0-9]+[-+]?[0-9]*个月'
   OR work_experience ~ '年限'
   OR work_experience = '[]'  -- 清空空数组字符串
   OR work_experience = '{}'; -- 清空空对象字符串

-- 验证更新结果
SELECT 
    id,
    name,
    work_experience,
    experience
FROM recruitment_process
WHERE work_experience IS NOT NULL 
  AND work_experience != ''
LIMIT 10;
