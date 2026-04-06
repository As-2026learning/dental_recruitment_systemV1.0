-- 创建工种表
CREATE TABLE IF NOT EXISTS job_types (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 添加注释
COMMENT ON TABLE job_types IS '工种类型表';
COMMENT ON COLUMN job_types.name IS '工种名称';
COMMENT ON COLUMN job_types.sort_order IS '排序顺序';
COMMENT ON COLUMN job_types.is_active IS '是否启用';

-- 插入默认工种数据
INSERT INTO job_types (name, sort_order, is_active) VALUES
    ('上瓷', 1, true),
    ('车瓷', 2, true),
    ('上釉', 3, true)
ON CONFLICT DO NOTHING;
