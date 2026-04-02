-- ============================================
-- 义齿工厂面试预约系统 - 数据库诊断与修复脚本
-- 请在 Supabase SQL Editor 中执行此脚本
-- ============================================

-- 1. 检查bookings表是否存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables 
                   WHERE table_schema = 'public' 
                   AND table_name = 'bookings') THEN
        -- 创建预约表
        CREATE TABLE public.bookings (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            phone VARCHAR(20) NOT NULL,
            position VARCHAR(100),
            booking_date DATE NOT NULL,
            time_slot VARCHAR(50) NOT NULL,
            notes TEXT,
            status VARCHAR(20) DEFAULT 'pending',
            application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        RAISE NOTICE '创建bookings表成功';
    ELSE
        RAISE NOTICE 'bookings表已存在';
    END IF;
END $$;

-- 2. 检查并添加缺失的列
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    -- 检查name列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'name'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN name VARCHAR(100) NOT NULL DEFAULT '';
        RAISE NOTICE '添加name列成功';
    ELSE
        RAISE NOTICE 'name列已存在';
    END IF;
    
    -- 检查phone列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'phone'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN phone VARCHAR(20) NOT NULL DEFAULT '';
        RAISE NOTICE '添加phone列成功';
    ELSE
        RAISE NOTICE 'phone列已存在';
    END IF;
    
    -- 检查position列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'position'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN position VARCHAR(100);
        RAISE NOTICE '添加position列成功';
    ELSE
        RAISE NOTICE 'position列已存在';
    END IF;
    
    -- 检查booking_date列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'booking_date'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN booking_date DATE NOT NULL DEFAULT CURRENT_DATE;
        RAISE NOTICE '添加booking_date列成功';
    ELSE
        RAISE NOTICE 'booking_date列已存在';
    END IF;
    
    -- 检查time_slot列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'time_slot'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN time_slot VARCHAR(50) NOT NULL DEFAULT '';
        RAISE NOTICE '添加time_slot列成功';
    ELSE
        RAISE NOTICE 'time_slot列已存在';
    END IF;
    
    -- 检查notes列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'notes'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN notes TEXT;
        RAISE NOTICE '添加notes列成功';
    ELSE
        RAISE NOTICE 'notes列已存在';
    END IF;
    
    -- 检查status列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'status'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
        RAISE NOTICE '添加status列成功';
    ELSE
        RAISE NOTICE 'status列已存在';
    END IF;
    
    -- 检查application_id列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'application_id'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL;
        RAISE NOTICE '添加application_id列成功';
    ELSE
        RAISE NOTICE 'application_id列已存在';
    END IF;
    
    -- 检查created_at列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'created_at'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '添加created_at列成功';
    ELSE
        RAISE NOTICE 'created_at列已存在';
    END IF;
    
    -- 检查updated_at列
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'bookings' 
        AND column_name = 'updated_at'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        ALTER TABLE public.bookings ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '添加updated_at列成功';
    ELSE
        RAISE NOTICE 'updated_at列已存在';
    END IF;
END $$;

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_time_slot ON bookings(time_slot);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_phone ON bookings(phone);
CREATE INDEX IF NOT EXISTS idx_bookings_application_id ON bookings(application_id);

-- 4. 设置行级安全策略
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 删除已存在的策略（避免重复创建错误）
DROP POLICY IF EXISTS "Allow anonymous select on bookings" ON bookings;
DROP POLICY IF EXISTS "Allow anonymous insert on bookings" ON bookings;
DROP POLICY IF EXISTS "Allow anonymous update on bookings" ON bookings;
DROP POLICY IF EXISTS "Allow anonymous delete on bookings" ON bookings;

-- 创建新的策略
CREATE POLICY "Allow anonymous select on bookings" ON bookings
  FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on bookings" ON bookings
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on bookings" ON bookings
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on bookings" ON bookings
  FOR DELETE TO anon USING (true);

-- 5. 刷新表结构缓存
ANALYZE bookings;

-- 6. 验证表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'bookings'
ORDER BY ordinal_position;

-- 完成
SELECT 'bookings表诊断与修复完成！' as message;
