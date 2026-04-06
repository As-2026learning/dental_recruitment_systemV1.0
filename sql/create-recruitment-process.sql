-- ============================================
-- 义齿工厂招聘系统 - 招聘流程管理模块数据库脚本
-- 整合方案 - 单表结构
-- ============================================

-- 删除已存在的表（如果存在）
DROP TABLE IF EXISTS recruitment_process CASCADE;

-- ============================================
-- 创建招聘流程主表
-- ============================================
CREATE TABLE recruitment_process (
    id SERIAL PRIMARY KEY,
    
    -- ============================================
    -- 1. 基础信息（同步自applications表）
    -- ============================================
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    gender VARCHAR(10),
    phone VARCHAR(20) NOT NULL,
    age INT,
    id_card VARCHAR(20),
    email VARCHAR(100),
    birth_date DATE,
    position VARCHAR(100),
    position_id INT,
    position_name VARCHAR(100),
    job_type VARCHAR(50),
    education VARCHAR(50),
    experience VARCHAR(50),
    current_residence VARCHAR(200),
    hometown VARCHAR(200),
    marital_status VARCHAR(20),
    political_status VARCHAR(50),
    health_status VARCHAR(100),
    skills TEXT,
    work_experience TEXT,
    salary_expectation VARCHAR(100),
    self_evaluation TEXT,
    career_plan TEXT,
    emergency_contact VARCHAR(100),
    emergency_phone VARCHAR(20),
    notes TEXT,
    dynamic_fields JSONB,
    source_status VARCHAR(20) DEFAULT 'pending',
    source_channel VARCHAR(50),
    
    -- ============================================
    -- 2. 流程状态
    -- ============================================
    current_stage VARCHAR(50) NOT NULL DEFAULT 'first_interview',
    current_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    
    -- ============================================
    -- 3. 初试环节信息 (JSONB格式存储)
    -- ============================================
    first_interview JSONB DEFAULT NULL,
    -- 兼容旧字段，保留但不使用
    first_interview_time TIMESTAMP,
    first_interviewer VARCHAR(100),
    first_interview_result VARCHAR(20),
    first_reject_reason VARCHAR(100),
    first_reject_detail TEXT,
    
    -- ============================================
    -- 4. 复试环节信息
    -- ============================================
    second_interview_time TIMESTAMP,
    second_interviewer VARCHAR(100),
    second_interview_result VARCHAR(20),
    second_reject_reason VARCHAR(100),
    second_reject_detail TEXT,
    hire_department VARCHAR(100),
    hire_position VARCHAR(100),
    job_title VARCHAR(100),
    job_level VARCHAR(50),
    hire_salary VARCHAR(100),
    accept_offer VARCHAR(20),
    offer_reject_reason TEXT,
    hire_date DATE,
    
    -- ============================================
    -- 5. 报到环节信息
    -- ============================================
    is_reported VARCHAR(20),
    report_date DATE,
    no_report_reason VARCHAR(100),
    no_report_detail TEXT,
    
    -- ============================================
    -- 6. 系统字段
    -- ============================================
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    source_type VARCHAR(20) DEFAULT 'sync',
    is_manual_add BOOLEAN DEFAULT FALSE
);

-- 添加表注释
COMMENT ON TABLE recruitment_process IS '招聘流程主表 - 整合方案单表结构，包含初试、复试、录用报到全流程信息';

-- ============================================
-- 创建索引
-- ============================================
-- 核心查询索引
CREATE INDEX idx_recruitment_app_id ON recruitment_process(application_id);
CREATE INDEX idx_recruitment_phone ON recruitment_process(phone);
CREATE INDEX idx_recruitment_stage ON recruitment_process(current_stage);
CREATE INDEX idx_recruitment_status ON recruitment_process(current_status);
CREATE INDEX idx_recruitment_first_result ON recruitment_process(first_interview_result);
CREATE INDEX idx_recruitment_second_result ON recruitment_process(second_interview_result);
CREATE INDEX idx_recruitment_is_reported ON recruitment_process(is_reported);
CREATE INDEX idx_recruitment_created_at ON recruitment_process(created_at);

-- 复合索引
CREATE INDEX idx_recruitment_stage_status ON recruitment_process(current_stage, current_status);
CREATE INDEX idx_recruitment_position_stage ON recruitment_process(position, current_stage);

-- ============================================
-- 创建触发器函数：自动更新 updated_at 字段
-- ============================================
CREATE OR REPLACE FUNCTION update_recruitment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER trigger_recruitment_updated_at
    BEFORE UPDATE ON recruitment_process
    FOR EACH ROW
    EXECUTE FUNCTION update_recruitment_updated_at();

-- ============================================
-- 设置行级安全策略 (RLS)
-- ============================================
ALTER TABLE recruitment_process ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous select on recruitment_process"
    ON recruitment_process FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on recruitment_process"
    ON recruitment_process FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on recruitment_process"
    ON recruitment_process FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous delete on recruitment_process"
    ON recruitment_process FOR DELETE TO anon USING (true);

-- ============================================
-- 创建数据同步函数：从 applications 表同步数据
-- ============================================
CREATE OR REPLACE FUNCTION sync_application_to_recruitment(app_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO recruitment_process (
        application_id,
        name,
        gender,
        phone,
        age,
        position,
        position_id,
        position_name,
        job_type,
        education,
        experience,
        skills,
        work_experience,
        salary_expectation,
        notes,
        dynamic_fields,
        source_status,
        source_type,
        is_manual_add
    )
    SELECT 
        a.id,
        a.name,
        a.gender,
        a.phone,
        a.age,
        a.position,
        a.position_id,
        a.position_name,
        a.job_type,
        a.education,
        a.experience,
        a.skills,
        a.work_experience,
        a.salary_expectation,
        a.notes,
        a.dynamic_fields,
        a.status,
        'sync',
        FALSE
    FROM applications a
    WHERE a.id = app_id
    ON CONFLICT (application_id) DO UPDATE SET
        name = EXCLUDED.name,
        gender = EXCLUDED.gender,
        phone = EXCLUDED.phone,
        age = EXCLUDED.age,
        position = EXCLUDED.position,
        position_id = EXCLUDED.position_id,
        position_name = EXCLUDED.position_name,
        job_type = EXCLUDED.job_type,
        education = EXCLUDED.education,
        experience = EXCLUDED.experience,
        skills = EXCLUDED.skills,
        work_experience = EXCLUDED.work_experience,
        salary_expectation = EXCLUDED.salary_expectation,
        notes = EXCLUDED.notes,
        dynamic_fields = EXCLUDED.dynamic_fields,
        source_status = EXCLUDED.source_status,
        updated_at = NOW()
    RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 创建手动添加记录的函数
-- ============================================
CREATE OR REPLACE FUNCTION add_manual_recruitment(
    p_name VARCHAR(100),
    p_phone VARCHAR(20),
    p_position VARCHAR(100),
    p_job_type VARCHAR(50) DEFAULT NULL,
    p_education VARCHAR(50) DEFAULT NULL,
    p_experience VARCHAR(50) DEFAULT NULL,
    p_dynamic_fields JSONB DEFAULT NULL,
    p_created_by VARCHAR(100) DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO recruitment_process (
        name,
        phone,
        position,
        job_type,
        education,
        experience,
        dynamic_fields,
        source_type,
        is_manual_add,
        created_by,
        updated_by
    ) VALUES (
        p_name,
        p_phone,
        p_position,
        p_job_type,
        p_education,
        p_experience,
        p_dynamic_fields,
        'manual',
        TRUE,
        p_created_by,
        p_created_by
    )
    RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 完成提示
-- ============================================
SELECT '招聘流程管理模块数据库表创建完成！' as message;
SELECT '表名：recruitment_process' as table_name;
SELECT '字段数：42个' as field_count;
