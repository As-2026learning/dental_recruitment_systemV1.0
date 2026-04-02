-- =====================================================
-- 义齿工厂招聘系统 - 数据库迁移脚本
-- 用于创建表结构、添加外键关联和优化数据模型
-- =====================================================

-- 0. 创建基础表结构

-- 创建 applications 表
CREATE TABLE IF NOT EXISTS applications (
    id SERIAL PRIMARY KEY,
    position TEXT,
    name TEXT,
    phone TEXT,
    age INTEGER,
    gender TEXT,
    education TEXT,
    experience TEXT,
    status TEXT DEFAULT 'pending',
    form_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 如果 applications 表已存在但缺少 form_data 列，添加该列
ALTER TABLE applications
ADD COLUMN IF NOT EXISTS form_data JSONB;

-- 创建 bookings 表
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    name TEXT,
    phone TEXT,
    position TEXT,
    booking_date DATE,
    time_slot TEXT,
    status TEXT DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 1. 在 bookings 表中添加 application_id 外键字段
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL;

-- 2. 创建索引以提高关联查询性能
CREATE INDEX IF NOT EXISTS idx_bookings_application_id ON bookings(application_id);
CREATE INDEX IF NOT EXISTS idx_bookings_phone ON bookings(phone);
CREATE INDEX IF NOT EXISTS idx_applications_phone ON applications(phone);

-- 3. 创建视图：应聘信息与预约信息整合视图
CREATE OR REPLACE VIEW application_booking_view AS
SELECT 
    a.id as application_id,
    a.name as applicant_name,
    a.phone as applicant_phone,
    a."position" as position_name,
    a.education,
    a.experience,
    a.status as application_status,
    a.form_data,
    a.created_at as application_date,
    b.id as booking_id,
    b.booking_date,
    b.time_slot,
    b.status as booking_status,
    b.notes as booking_notes,
    b.created_at as booking_created_at
FROM applications a
LEFT JOIN bookings b ON a.id = b.application_id OR (a.phone = b.phone AND b.application_id IS NULL)
ORDER BY a.created_at DESC;

-- 4. 数据迁移：为现有 booking 记录关联 application_id
UPDATE bookings b
SET application_id = a.id
FROM applications a
WHERE b.phone = a.phone 
AND b.application_id IS NULL;

-- 5. 创建函数：获取完整的应聘信息（包含预约信息）
CREATE OR REPLACE FUNCTION get_application_with_booking(app_id INTEGER)
RETURNS TABLE (
    application_id INTEGER,
    applicant_name TEXT,
    applicant_phone TEXT,
    position_name TEXT,
    education TEXT,
    experience TEXT,
    application_status TEXT,
    form_data JSONB,
    application_date TIMESTAMP WITH TIME ZONE,
    booking_id INTEGER,
    booking_date DATE,
    time_slot TEXT,
    booking_status TEXT,
    booking_notes TEXT,
    booking_created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.phone,
        a."position",
        a.education,
        a.experience,
        a.status,
        a.form_data,
        a.created_at,
        b.id,
        b.booking_date,
        b.time_slot,
        b.status,
        b.notes,
        b.created_at
    FROM applications a
    LEFT JOIN bookings b ON a.id = b.application_id
    WHERE a.id = app_id;
END;
$$ LANGUAGE plpgsql;

-- 6. 创建函数：获取所有应聘信息列表（包含预约状态）
CREATE OR REPLACE FUNCTION get_applications_list(
    p_position TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_search TEXT DEFAULT NULL
)
RETURNS TABLE (
    id INTEGER,
    name TEXT,
    phone TEXT,
    "position" TEXT,
    education TEXT,
    experience TEXT,
    status TEXT,
    form_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE,
    has_booking BOOLEAN,
    booking_date DATE,
    booking_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.phone,
        a."position",
        a.education,
        a.experience,
        a.status,
        a.form_data,
        a.created_at,
        EXISTS(SELECT 1 FROM bookings b WHERE b.application_id = a.id OR b.phone = a.phone) as has_booking,
        (SELECT b.booking_date FROM bookings b WHERE b.application_id = a.id OR b.phone = a.phone ORDER BY b.created_at DESC LIMIT 1),
        (SELECT b.status FROM bookings b WHERE b.application_id = a.id OR b.phone = a.phone ORDER BY b.created_at DESC LIMIT 1)
    FROM applications a
    WHERE 
        (p_position IS NULL OR a."position" = p_position)
        AND (p_status IS NULL OR a.status = p_status)
        AND (p_search IS NULL OR 
             a.name ILIKE '%' || p_search || '%' OR 
             a.phone ILIKE '%' || p_search || '%')
    ORDER BY a.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 7. 创建触发器：当插入新的预约记录时，自动关联 application_id
CREATE OR REPLACE FUNCTION auto_link_booking_to_application()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果 application_id 为空，尝试通过手机号关联
    IF NEW.application_id IS NULL AND NEW.phone IS NOT NULL THEN
        SELECT id INTO NEW.application_id
        FROM applications
        WHERE phone = NEW.phone
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 删除已存在的触发器（如果存在）
DROP TRIGGER IF EXISTS trg_auto_link_booking ON bookings;

-- 创建触发器
CREATE TRIGGER trg_auto_link_booking
    BEFORE INSERT ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION auto_link_booking_to_application();

-- 8. 创建模板和字段相关表结构

-- 创建 templates 表
CREATE TABLE IF NOT EXISTS templates (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 field_configs 表
CREATE TABLE IF NOT EXISTS field_configs (
    id SERIAL PRIMARY KEY,
    field_name TEXT NOT NULL,
    field_label TEXT NOT NULL,
    field_type TEXT NOT NULL,
    is_required BOOLEAN DEFAULT false,
    default_value TEXT,
    validation_rule TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 template_field_mappings 表
CREATE TABLE IF NOT EXISTS template_field_mappings (
    id SERIAL PRIMARY KEY,
    template_id INTEGER REFERENCES templates(id) ON DELETE CASCADE,
    field_id INTEGER REFERENCES field_configs(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 999,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(template_id, field_id)
);

-- 创建 field_options 表
CREATE TABLE IF NOT EXISTS field_options (
    id SERIAL PRIMARY KEY,
    field_id INTEGER REFERENCES field_configs(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    value TEXT NOT NULL,
    sort_order INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 time_slots 表
CREATE TABLE IF NOT EXISTS time_slots (
    id SERIAL PRIMARY KEY,
    slot_key TEXT NOT NULL UNIQUE,
    label TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    capacity INTEGER DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 positions 表
CREATE TABLE IF NOT EXISTS positions (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建 system_config 表
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key TEXT NOT NULL UNIQUE,
    config_value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. 插入默认数据

-- 插入默认模板
INSERT INTO templates (id, name, description) VALUES
(1, '基础模板', '包含基本个人信息字段'),
(2, '技术岗位模板', '包含技术技能相关字段')
ON CONFLICT (id) DO NOTHING;

-- 插入默认字段
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

-- 插入默认字段选项
INSERT INTO field_options (field_id, label, value, sort_order) VALUES
(2, '男', '男', 1),
(2, '女', '女', 2),
(5, '初中及以下', '初中及以下', 1),
(5, '高中/中专', '高中/中专', 2),
(5, '大专', '大专', 3),
(5, '本科', '本科', 4),
(5, '研究生及以上', '研究生及以上', 5),
(6, '无经验', '无经验', 1),
(6, '1年以下', '1年以下', 2),
(6, '1-3年', '1-3年', 3),
(6, '3-5年', '3-5年', 4),
(6, '5年以上', '5年以上', 5),
(7, '内部介绍', '内部介绍', 1),
(7, '招聘网站', '招聘网站', 2),
(7, '社交媒体', '社交媒体', 3),
(7, '线下招聘', '线下招聘', 4),
(7, '其他', '其他', 5)
ON CONFLICT (id) DO NOTHING;

-- 插入模板字段映射
INSERT INTO template_field_mappings (template_id, field_id, is_enabled, sort_order) VALUES
(1, 1, true, 1),
(1, 2, true, 2),
(1, 3, true, 3),
(1, 4, true, 4),
(1, 5, true, 5),
(1, 6, true, 6),
(1, 7, true, 7),
(1, 8, true, 8),
(2, 1, true, 1),
(2, 2, true, 2),
(2, 3, true, 3),
(2, 4, true, 4),
(2, 5, true, 5),
(2, 6, true, 6),
(2, 7, true, 7),
(2, 8, true, 8)
ON CONFLICT (template_id, field_id) DO NOTHING;

-- 插入默认时段
INSERT INTO time_slots (slot_key, label, start_time, end_time, capacity, sort_order) VALUES
('slot_1', '上午场 09:00-10:00', '09:00', '10:00', 10, 1),
('slot_2', '上午场 10:00-10:30', '10:00', '10:30', 5, 2),
('slot_3', '下午场 13:00-14:00', '13:00', '14:00', 10, 3),
('slot_4', '下午场 14:00-15:00', '14:00', '15:00', 10, 4),
('slot_5', '下午场 15:00-15:30', '15:00', '15:30', 5, 5)
ON CONFLICT (slot_key) DO NOTHING;

-- 插入默认岗位
INSERT INTO positions (name, sort_order) VALUES
('学徒', 1),
('普工', 2),
('牙科技工', 3),
('牙科质检员', 4)
ON CONFLICT (name) DO NOTHING;

-- 插入默认系统配置
INSERT INTO system_config (config_key, config_value, description) VALUES
('booking_notice', '面试时间：周一至周五|请提前至少2小时预约|请确保联系方式正确', '预约须知'),
('success_tips', '请携带身份证原件准时到达|如需修改或取消预约，请致电：XXX-XXXX-XXXX|面试地点：XXXXXXXXXXXXXXXX', '成功提示'),
('banner_settings', '系统设置', '设置页面横幅'),
('banner_booking', '面试预约', '预约页面横幅'),
('banner_admin', '预约管理', '管理页面横幅')
ON CONFLICT (config_key) DO NOTHING;

-- =====================================================
-- 迁移完成！
-- =====================================================
