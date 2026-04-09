-- =====================================================
-- 义齿工厂招聘系统 - 数据库表创建脚本
-- 在 Supabase SQL 编辑器中执行此脚本
-- =====================================================

-- 1. 创建模板表
CREATE TABLE IF NOT EXISTS templates (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建字段配置表
CREATE TABLE IF NOT EXISTS field_configs (
    id SERIAL PRIMARY KEY,
    field_name VARCHAR(100) NOT NULL,
    field_label VARCHAR(200) NOT NULL,
    field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('text', 'textarea', 'number', 'select', 'radio', 'checkbox', 'date')),
    is_required BOOLEAN DEFAULT false,
    default_value TEXT,
    validation_rule VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建模板字段映射表
CREATE TABLE IF NOT EXISTS template_field_mappings (
    id SERIAL PRIMARY KEY,
    template_id INTEGER NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    field_id INTEGER NOT NULL REFERENCES field_configs(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 999,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(template_id, field_id)
);

-- 4. 创建字段选项表
CREATE TABLE IF NOT EXISTS field_options (
    id SERIAL PRIMARY KEY,
    field_id INTEGER NOT NULL REFERENCES field_configs(id) ON DELETE CASCADE,
    label VARCHAR(200) NOT NULL,
    value VARCHAR(200) NOT NULL,
    sort_order INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 插入默认模板
INSERT INTO templates (id, name, description) VALUES
(1, '基础模板', '包含基本个人信息字段'),
(2, '技术岗位模板', '包含技术技能相关字段')
ON CONFLICT (id) DO NOTHING;

-- 6. 插入默认字段配置
INSERT INTO field_configs (id, field_name, field_label, field_type, is_required, default_value, validation_rule) VALUES
(1, 'name', '姓名', 'text', true, '', ''),
(2, 'gender', '性别', 'radio', true, '', ''),
(3, 'age', '年龄', 'number', true, '', 'number'),
(4, 'phone', '联系电话', 'text', true, '', 'phone'),
(5, 'education', '学历', 'select', true, '', ''),
(6, 'experience', '工作经验', 'select', true, '', ''),
(7, 'source_channel', '招聘渠道', 'select', true, '', ''),
(8, 'self_introduction', '自我介绍', 'textarea', false, '', '')
ON CONFLICT (id) DO NOTHING;

-- 7. 插入默认字段选项
INSERT INTO field_options (field_id, label, value, sort_order) VALUES
-- 性别选项 (field_id = 2)
(2, '男', '男', 1),
(2, '女', '女', 2),
-- 学历选项 (field_id = 5)
(5, '初中及以下', '初中及以下', 1),
(5, '高中/中专', '高中/中专', 2),
(5, '大专', '大专', 3),
(5, '本科', '本科', 4),
(5, '研究生及以上', '研究生及以上', 5),
-- 工作经验选项 (field_id = 6)
(6, '无经验', '无经验', 1),
(6, '1年以下', '1年以下', 2),
(6, '1-3年', '1-3年', 3),
(6, '3-5年', '3-5年', 4),
(6, '5年以上', '5年以上', 5),
-- 招聘渠道选项 (field_id = 7)
(7, '内部介绍', '内部介绍', 1),
(7, '招聘网站', '招聘网站', 2),
(7, '社交媒体', '社交媒体', 3),
(7, '线下招聘', '线下招聘', 4),
(7, '其他', '其他', 5)
ON CONFLICT DO NOTHING;

-- 8. 插入模板字段映射
INSERT INTO template_field_mappings (template_id, field_id, is_enabled, sort_order) VALUES
-- 基础模板 (template_id = 1)
(1, 1, true, 1),
(1, 2, true, 2),
(1, 3, true, 3),
(1, 4, true, 4),
(1, 5, true, 5),
(1, 6, true, 6),
(1, 7, true, 7),
(1, 8, true, 8),
-- 技术岗位模板 (template_id = 2)
(2, 1, true, 1),
(2, 2, true, 2),
(2, 3, true, 3),
(2, 4, true, 4),
(2, 5, true, 5),
(2, 6, true, 6),
(2, 7, true, 7),
(2, 8, true, 8)
ON CONFLICT DO NOTHING;

-- 9. 设置序列起始值（确保新记录的ID正确）
SELECT setval('templates_id_seq', COALESCE((SELECT MAX(id) FROM templates), 0) + 1, false);
SELECT setval('field_configs_id_seq', COALESCE((SELECT MAX(id) FROM field_configs), 0) + 1, false);
SELECT setval('template_field_mappings_id_seq', COALESCE((SELECT MAX(id) FROM template_field_mappings), 0) + 1, false);
SELECT setval('field_options_id_seq', COALESCE((SELECT MAX(id) FROM field_options), 0) + 1, false);

-- =====================================================
-- 完成！所有表和默认数据已创建
-- =====================================================
