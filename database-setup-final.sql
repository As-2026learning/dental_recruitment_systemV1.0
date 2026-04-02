-- 最终数据库适配脚本
-- 检查并添加所有缺失的字段

-- 检查并添加field_configs表缺失字段
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS field_name TEXT;
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS field_label TEXT;
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS field_type TEXT;
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS is_required BOOLEAN DEFAULT false;
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS default_value TEXT;
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS validation_rule TEXT;
ALTER TABLE public.field_configs ADD COLUMN IF NOT EXISTS is_frontend BOOLEAN DEFAULT true;

-- 检查并添加field_options表缺失字段
ALTER TABLE public.field_options ADD COLUMN IF NOT EXISTS field_id INTEGER;
ALTER TABLE public.field_options ADD COLUMN IF NOT EXISTS label TEXT;
ALTER TABLE public.field_options ADD COLUMN IF NOT EXISTS value TEXT;
ALTER TABLE public.field_options ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

-- 检查并添加template_field_mappings表缺失字段
ALTER TABLE public.template_field_mappings ADD COLUMN IF NOT EXISTS template_id INTEGER;
ALTER TABLE public.template_field_mappings ADD COLUMN IF NOT EXISTS field_id INTEGER;
ALTER TABLE public.template_field_mappings ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE public.template_field_mappings ADD COLUMN IF NOT EXISTS is_enabled BOOLEAN DEFAULT true;

-- 创建必要的外键约束（如果不存在）
ALTER TABLE public.field_options ADD CONSTRAINT IF NOT EXISTS field_options_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.field_configs(id) ON DELETE CASCADE;

ALTER TABLE public.template_field_mappings ADD CONSTRAINT IF NOT EXISTS template_field_mappings_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.templates(id) ON DELETE CASCADE;
ALTER TABLE public.template_field_mappings ADD CONSTRAINT IF NOT EXISTS template_field_mappings_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.field_configs(id) ON DELETE CASCADE;
ALTER TABLE public.template_field_mappings ADD CONSTRAINT IF NOT EXISTS template_field_mappings_template_id_field_id_key UNIQUE (template_id, field_id);

-- 插入默认字段配置
INSERT INTO public.field_configs (field_name, field_label, field_type, is_required, default_value, validation_rule, is_frontend)
VALUES 
    ('name', '姓名', 'text', true, '', '', true),
    ('gender', '性别', 'radio', true, '', '', true),
    ('age', '年龄', 'number', true, '', 'number', true),
    ('phone', '联系电话', 'text', true, '', 'phone', true),
    ('education', '学历', 'select', true, '', '', true),
    ('experience', '工作经验', 'select', true, '', '', true),
    ('source_channel', '招聘渠道', 'select', true, '', '', true),
    ('self_introduction', '自我介绍', 'textarea', false, '', '', true)
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