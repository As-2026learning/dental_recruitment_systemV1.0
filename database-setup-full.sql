-- 完整数据库表结构创建脚本
-- 使用CREATE TABLE IF NOT EXISTS避免重复创建

-- 创建positions表
CREATE TABLE IF NOT EXISTS public.positions (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建time_slots表
CREATE TABLE IF NOT EXISTS public.time_slots (
    id SERIAL PRIMARY KEY,
    slot_key TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 10,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建system_config表
CREATE TABLE IF NOT EXISTS public.system_config (
    id SERIAL PRIMARY KEY,
    config_key TEXT NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建applications表
CREATE TABLE IF NOT EXISTS public.applications (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    position TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建bookings表
CREATE TABLE IF NOT EXISTS public.bookings (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    booking_date DATE NOT NULL,
    time_slot TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建templates表
CREATE TABLE IF NOT EXISTS public.templates (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建field_configs表
CREATE TABLE IF NOT EXISTS public.field_configs (
    id SERIAL PRIMARY KEY,
    field_name TEXT NOT NULL,
    field_label TEXT NOT NULL,
    field_type TEXT NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT false,
    default_value TEXT,
    validation_rule TEXT,
    is_frontend BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建field_options表
CREATE TABLE IF NOT EXISTS public.field_options (
    id SERIAL PRIMARY KEY,
    field_id INTEGER NOT NULL REFERENCES public.field_configs(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    value TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建template_field_mappings表
CREATE TABLE IF NOT EXISTS public.template_field_mappings (
    id SERIAL PRIMARY KEY,
    template_id INTEGER NOT NULL REFERENCES public.templates(id) ON DELETE CASCADE,
    field_id INTEGER NOT NULL REFERENCES public.field_configs(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(template_id, field_id)
);

-- 插入默认数据（使用ON CONFLICT DO NOTHING避免重复插入）
INSERT INTO public.positions (name, sort_order, is_active)
VALUES 
    ('口腔医生', 1, true),
    ('牙科技工', 2, true),
    ('口腔护士', 3, true),
    ('前台接待', 4, true),
    ('市场专员', 5, true)
ON CONFLICT DO NOTHING;

INSERT INTO public.time_slots (slot_key, label, start_time, end_time, capacity, sort_order, is_active)
VALUES 
    ('slot_1', '上午场 09:00-10:00', '09:00', '10:00', 10, 1, true),
    ('slot_2', '上午场 10:00-10:30', '10:00', '10:30', 5, 2, true),
    ('slot_3', '下午场 13:00-14:00', '13:00', '14:00', 10, 3, true),
    ('slot_4', '下午场 14:00-15:00', '14:00', '15:00', 10, 4, true),
    ('slot_5', '下午场 15:00-15:30', '15:00', '15:30', 5, 5, true)
ON CONFLICT (slot_key) DO NOTHING;

INSERT INTO public.system_config (config_key, config_value, description)
VALUES 
    ('booking_notice', '面试时间：周一至周五|请提前至少2小时预约|请确保联系方式正确', '预约须知'),
    ('success_tips', '请携带身份证原件准时到达|如需修改或取消预约，请致电：XXX-XXXX-XXXX|面试地点：XXXXXXXXXXXXXXXX', '预约成功提示'),
    ('banner_settings', '系统设置', '设置页面横幅'),
    ('banner_booking', '面试预约', '预约页面横幅'),
    ('banner_admin', '应聘与预约管理', '管理页面横幅')
ON CONFLICT (config_key) DO NOTHING;

INSERT INTO public.templates (name, description, is_active)
VALUES 
    ('基础模板', '包含基本个人信息字段', true),
    ('技术岗位模板', '包含技术技能相关字段', true)
ON CONFLICT DO NOTHING;

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
SELECT 'positions' as table_name, COUNT(*) as row_count FROM public.positions;
SELECT 'time_slots' as table_name, COUNT(*) as row_count FROM public.time_slots;
SELECT 'system_config' as table_name, COUNT(*) as row_count FROM public.system_config;
SELECT 'applications' as table_name, COUNT(*) as row_count FROM public.applications;
SELECT 'bookings' as table_name, COUNT(*) as row_count FROM public.bookings;
SELECT 'templates' as table_name, COUNT(*) as row_count FROM public.templates;
SELECT 'field_configs' as table_name, COUNT(*) as row_count FROM public.field_configs;
SELECT 'field_options' as table_name, COUNT(*) as row_count FROM public.field_options;
SELECT 'template_field_mappings' as table_name, COUNT(*) as row_count FROM public.template_field_mappings;