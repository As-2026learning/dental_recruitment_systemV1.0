-- 适配现有表结构的数据库脚本
-- 使用ALTER TABLE添加缺失字段

-- 检查并添加缺失的字段
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS is_frontend BOOLEAN NOT NULL DEFAULT true;

-- 插入默认字段配置（不包含is_frontend字段，使用表的默认值）
INSERT INTO public.field_configs (field_name, field_label, field_type, is_required, default_value, validation_rule)
VALUES 
    ('name', '姓名', 'text', true, '', ''),
    ('gender', '性别', 'radio', true, '', ''),
    ('age', '年龄', 'number', true, '', 'number'),
    ('phone', '联系电话', 'text', true, '', 'phone'),
    ('education', '学历', 'select', true, '', ''),
    ('experience', '工作经验', 'select', true, '', ''),
    ('source_channel', '招聘渠道', 'select', true, '', ''),
    ('self_introduction', '自我介绍', 'textarea', false, '', '')
ON CONFLICT DO NOTHING;

-- 插入默认字段选项
INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '男', '男', 1 FROM public.field_configs WHERE field_name = 'gender'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '女', '女', 2 FROM public.field_configs WHERE field_name = 'gender'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '初中及以下', '初中及以下', 1 FROM public.field_configs WHERE field_name = 'education'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '高中/中专', '高中/中专', 2 FROM public.field_configs WHERE field_name = 'education'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '大专', '大专', 3 FROM public.field_configs WHERE field_name = 'education'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '本科', '本科', 4 FROM public.field_configs WHERE field_name = 'education'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '研究生及以上', '研究生及以上', 5 FROM public.field_configs WHERE field_name = 'education'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '无经验', '无经验', 1 FROM public.field_configs WHERE field_name = 'experience'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '1年以下', '1年以下', 2 FROM public.field_configs WHERE field_name = 'experience'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '1-3年', '1-3年', 3 FROM public.field_configs WHERE field_name = 'experience'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '3-5年', '3-5年', 4 FROM public.field_configs WHERE field_name = 'experience'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '5年以上', '5年以上', 5 FROM public.field_configs WHERE field_name = 'experience'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '内部介绍', '内部介绍', 1 FROM public.field_configs WHERE field_name = 'source_channel'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '招聘网站', '招聘网站', 2 FROM public.field_configs WHERE field_name = 'source_channel'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '社交媒体', '社交媒体', 3 FROM public.field_configs WHERE field_name = 'source_channel'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '线下招聘', '线下招聘', 4 FROM public.field_configs WHERE field_name = 'source_channel'
ON CONFLICT DO NOTHING;

INSERT INTO public.field_options (field_id, label, value, sort_order)
SELECT id, '其他', '其他', 5 FROM public.field_configs WHERE field_name = 'source_channel'
ON CONFLICT DO NOTHING;

-- 关联模板和字段
INSERT INTO public.template_field_mappings (template_id, field_id, sort_order, is_enabled)
SELECT 
    t.id as template_id,
    f.id as field_id,
    ROW_NUMBER() OVER (ORDER BY f.id) as sort_order,
    true as is_enabled
FROM 
    public.templates t,
    public.field_configs f
WHERE 
    t.name = '基础模板'
ON CONFLICT (template_id, field_id) DO NOTHING;

-- 验证表结构
SELECT 'field_configs' as table_name, COUNT(*) as row_count FROM public.field_configs;
SELECT 'field_options' as table_name, COUNT(*) as row_count FROM public.field_options;
SELECT 'template_field_mappings' as table_name, COUNT(*) as row_count FROM public.template_field_mappings;