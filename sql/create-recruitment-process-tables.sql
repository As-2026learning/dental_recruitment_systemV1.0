-- ============================================
-- 义齿工厂招聘系统 - 招聘流程管理模块数据库设计
-- 第一阶段：数据库表结构设计
-- ============================================

-- ============================================
-- 方案A：整合方案 - 单表结构
-- 将招聘流程所有环节信息整合到同一表中
-- ============================================

-- 创建招聘流程主表（整合方案）
CREATE TABLE IF NOT EXISTS recruitment_process_integrated (
    -- 主键
    id SERIAL PRIMARY KEY,
    
    -- ============================================
    -- 1. 完整同步 applications 表的所有字段
    -- ============================================
    
    -- 基础信息字段（来自applications表）
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL, -- 关联原应聘记录
    name VARCHAR(100) NOT NULL,                    -- 姓名
    gender VARCHAR(10),                            -- 性别
    phone VARCHAR(20) NOT NULL,                    -- 电话
    age INT,                                       -- 年龄
    position VARCHAR(100),                         -- 应聘岗位
    position_id INT,                               -- 岗位ID
    position_name VARCHAR(100),                    -- 岗位名称
    job_type VARCHAR(50),                          -- 工种
    education VARCHAR(50),                         -- 学历
    experience VARCHAR(50),                        -- 工作经验
    skills TEXT,                                   -- 技能
    work_experience TEXT,                          -- 工作经历
    salary_expectation VARCHAR(100),               -- 薪资期望
    notes TEXT,                                    -- 备注
    dynamic_fields JSONB,                          -- 动态字段（JSON格式）
    
    -- 原表状态字段
    source_status VARCHAR(20) DEFAULT 'pending',   -- 原应聘状态
    
    -- ============================================
    -- 2. 招聘流程核心字段
    -- ============================================
    
    -- 当前流程状态
    current_stage VARCHAR(50) NOT NULL DEFAULT 'first_interview', -- 当前环节
    current_status VARCHAR(50) NOT NULL DEFAULT 'pending',        -- 当前状态
    
    -- ============================================
    -- 3. 初试环节字段
    -- ============================================
    first_interview_time TIMESTAMP,                -- 初试时间
    first_interviewer VARCHAR(100),                -- 初试官
    first_interview_result VARCHAR(20),            -- 初试结果：pass/reject/pending
    first_reject_reason VARCHAR(100),              -- 未通过原因类型
    first_reject_detail TEXT,                      -- 未通过详细说明
    
    -- ============================================
    -- 4. 复试环节字段
    -- ============================================
    second_interview_time TIMESTAMP,               -- 复试时间
    second_interviewer VARCHAR(100),               -- 复试官
    second_interview_result VARCHAR(20),           -- 复试结果：pass/reject/pending
    second_reject_reason VARCHAR(100),             -- 未通过原因类型
    second_reject_detail TEXT,                     -- 未通过详细说明
    
    -- 录用信息（复试通过后填写）
    hire_department VARCHAR(100),                  -- 录用部门
    hire_position VARCHAR(100),                    -- 录用岗位
    job_level VARCHAR(50),                         -- 职级
    hire_salary VARCHAR(100),                      -- 录用薪资
    hire_date DATE,                                -- 预计入职日期
    
    -- ============================================
    -- 5. 报到（录用）环节字段
    -- ============================================
    is_reported VARCHAR(20),                       -- 是否报到：yes/no
    report_date DATE,                              -- 实际报到日期
    no_report_reason VARCHAR(100),                 -- 未报到原因
    no_report_detail TEXT,                         -- 未报到详细说明
    
    -- ============================================
    -- 6. 系统字段
    -- ============================================
    created_at TIMESTAMP DEFAULT NOW(),            -- 创建时间
    updated_at TIMESTAMP DEFAULT NOW(),            -- 更新时间
    created_by VARCHAR(100),                       -- 创建人
    updated_by VARCHAR(100),                       -- 更新人
    
    -- 数据来源标记
    source_type VARCHAR(20) DEFAULT 'sync',        -- 来源：sync(同步)/manual(手动添加)
    is_manual_add BOOLEAN DEFAULT FALSE            -- 是否为手动添加
);

-- 为整合方案表创建索引
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_app_id ON recruitment_process_integrated(application_id);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_phone ON recruitment_process_integrated(phone);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_stage ON recruitment_process_integrated(current_stage);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_status ON recruitment_process_integrated(current_status);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_first_result ON recruitment_process_integrated(first_interview_result);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_second_result ON recruitment_process_integrated(second_interview_result);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_is_reported ON recruitment_process_integrated(is_reported);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_created_at ON recruitment_process_integrated(created_at);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_source_type ON recruitment_process_integrated(source_type);

-- 创建复合索引用于常用查询
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_stage_status ON recruitment_process_integrated(current_stage, current_status);
CREATE INDEX IF NOT EXISTS idx_recruitment_integrated_position_stage ON recruitment_process_integrated(position, current_stage);

-- 添加表注释
COMMENT ON TABLE recruitment_process_integrated IS '招聘流程主表（整合方案）- 包含初试、复试、录用报到全流程信息';


-- ============================================
-- 方案B：分表方案 - 多表结构
-- 为每个环节创建独立数据表
-- ============================================

-- ----------------------------------------
-- B1. 招聘流程主表（基础信息 + 状态管理）
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS recruitment_process (
    id SERIAL PRIMARY KEY,
    
    -- 关联原应聘记录
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
    
    -- 基础信息（冗余存储，便于查询）
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    position VARCHAR(100),
    job_type VARCHAR(50),
    education VARCHAR(50),
    experience VARCHAR(50),
    dynamic_fields JSONB,
    
    -- 当前流程状态
    current_stage VARCHAR(50) NOT NULL DEFAULT 'first_interview',
    current_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    
    -- 各环节关联ID
    first_interview_id INTEGER,
    second_interview_id INTEGER,
    onboarding_id INTEGER,
    
    -- 系统字段
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    
    -- 数据来源
    source_type VARCHAR(20) DEFAULT 'sync',
    is_manual_add BOOLEAN DEFAULT FALSE
);

-- 为主表创建索引
CREATE INDEX IF NOT EXISTS idx_recruitment_process_app_id ON recruitment_process(application_id);
CREATE INDEX IF NOT EXISTS idx_recruitment_process_phone ON recruitment_process(phone);
CREATE INDEX IF NOT EXISTS idx_recruitment_process_stage ON recruitment_process(current_stage);
CREATE INDEX IF NOT EXISTS idx_recruitment_process_status ON recruitment_process(current_status);

COMMENT ON TABLE recruitment_process IS '招聘流程主表（分表方案）- 管理流程状态和环节关联';


-- ----------------------------------------
-- B2. 初试环节表
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS recruitment_first_interview (
    id SERIAL PRIMARY KEY,
    
    -- 关联流程主表
    process_id INTEGER REFERENCES recruitment_process(id) ON DELETE CASCADE,
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
    
    -- 初试信息
    interview_time TIMESTAMP NOT NULL,             -- 初试时间
    interviewer VARCHAR(100) NOT NULL,             -- 初试官
    interview_result VARCHAR(20) NOT NULL,         -- 结果：pass/reject/pending
    reject_reason VARCHAR(100),                    -- 未通过原因类型
    reject_detail TEXT,                            -- 未通过详细说明
    
    -- 评价信息
    skill_evaluation TEXT,                         -- 技能评价
    attitude_evaluation TEXT,                      -- 态度评价
    comprehensive_score DECIMAL(3,1),              -- 综合评分
    
    -- 系统字段
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    operator VARCHAR(100)                          -- 操作人
);

CREATE INDEX IF NOT EXISTS idx_first_interview_process_id ON recruitment_first_interview(process_id);
CREATE INDEX IF NOT EXISTS idx_first_interview_result ON recruitment_first_interview(interview_result);
CREATE INDEX IF NOT EXISTS idx_first_interview_time ON recruitment_first_interview(interview_time);

COMMENT ON TABLE recruitment_first_interview IS '初试环节表（分表方案）- 存储初试相关信息';


-- ----------------------------------------
-- B3. 复试环节表
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS recruitment_second_interview (
    id SERIAL PRIMARY KEY,
    
    -- 关联流程主表
    process_id INTEGER REFERENCES recruitment_process(id) ON DELETE CASCADE,
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
    
    -- 关联初试记录
    first_interview_id INTEGER REFERENCES recruitment_first_interview(id) ON DELETE SET NULL,
    
    -- 复试信息
    interview_time TIMESTAMP NOT NULL,             -- 复试时间
    interviewer VARCHAR(100) NOT NULL,             -- 复试官
    interview_result VARCHAR(20) NOT NULL,         -- 结果：pass/reject/pending
    reject_reason VARCHAR(100),                    -- 未通过原因类型
    reject_detail TEXT,                            -- 未通过详细说明
    
    -- 录用信息（复试通过后填写）
    hire_department VARCHAR(100),                  -- 录用部门
    hire_position VARCHAR(100),                    -- 录用岗位
    job_level VARCHAR(50),                         -- 职级
    hire_salary VARCHAR(100),                      -- 录用薪资
    hire_date DATE,                                -- 预计入职日期
    
    -- 评价信息
    professional_evaluation TEXT,                  -- 专业能力评价
    comprehensive_evaluation TEXT,                 -- 综合评价
    comprehensive_score DECIMAL(3,1),              -- 综合评分
    
    -- 系统字段
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    operator VARCHAR(100)                          -- 操作人
);

CREATE INDEX IF NOT EXISTS idx_second_interview_process_id ON recruitment_second_interview(process_id);
CREATE INDEX IF NOT EXISTS idx_second_interview_result ON recruitment_second_interview(interview_result);
CREATE INDEX IF NOT EXISTS idx_second_interview_time ON recruitment_second_interview(interview_time);

COMMENT ON TABLE recruitment_second_interview IS '复试环节表（分表方案）- 存储复试及录用相关信息';


-- ----------------------------------------
-- B4. 报到（录用）环节表
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS recruitment_onboarding (
    id SERIAL PRIMARY KEY,
    
    -- 关联流程主表
    process_id INTEGER REFERENCES recruitment_process(id) ON DELETE CASCADE,
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
    
    -- 关联复试记录
    second_interview_id INTEGER REFERENCES recruitment_second_interview(id) ON DELETE SET NULL,
    
    -- 报到信息
    is_reported VARCHAR(20) NOT NULL,              -- 是否报到：yes/no
    report_date DATE,                              -- 实际报到日期
    no_report_reason VARCHAR(100),                 -- 未报到原因
    no_report_detail TEXT,                         -- 未报到详细说明
    
    -- 入职信息（已报到时填写）
    employee_id VARCHAR(50),                       -- 员工编号
    department VARCHAR(100),                       -- 入职部门
    onboard_position VARCHAR(100),                 -- 入职岗位
    onboard_date DATE,                             -- 入职日期
    probation_period INT,                          -- 试用期（月）
    
    -- 系统字段
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    operator VARCHAR(100)                          -- 操作人
);

CREATE INDEX IF NOT EXISTS idx_onboarding_process_id ON recruitment_onboarding(process_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_is_reported ON recruitment_onboarding(is_reported);
CREATE INDEX IF NOT EXISTS idx_onboarding_report_date ON recruitment_onboarding(report_date);

COMMENT ON TABLE recruitment_onboarding IS '报到环节表（分表方案）- 存储报到及入职相关信息';


-- ----------------------------------------
-- B5. 流程历史记录表（两种方案共用）
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS recruitment_history (
    id SERIAL PRIMARY KEY,
    
    -- 关联信息（根据方案不同，可能关联不同表）
    process_id INTEGER,                            -- 流程ID
    application_id INTEGER REFERENCES applications(id) ON DELETE SET NULL,
    
    -- 操作信息
    stage VARCHAR(50) NOT NULL,                    -- 环节：first/second/onboarding
    action VARCHAR(50) NOT NULL,                   -- 操作类型
    old_status VARCHAR(50),                        -- 操作前状态
    new_status VARCHAR(50),                        -- 操作后状态
    old_data JSONB,                                -- 操作前数据（备份）
    new_data JSONB,                                -- 操作后数据（备份）
    
    -- 系统字段
    operator VARCHAR(100),                         -- 操作人
    operator_ip VARCHAR(50),                       -- 操作IP
    notes TEXT,                                    -- 备注
    created_at TIMESTAMP DEFAULT NOW()             -- 操作时间
);

CREATE INDEX IF NOT EXISTS idx_recruitment_history_process_id ON recruitment_history(process_id);
CREATE INDEX IF NOT EXISTS idx_recruitment_history_stage ON recruitment_history(stage);
CREATE INDEX IF NOT EXISTS idx_recruitment_history_created_at ON recruitment_history(created_at);

COMMENT ON TABLE recruitment_history IS '招聘流程历史记录表 - 记录所有操作变更历史';


-- ============================================
-- 创建触发器函数：自动更新 updated_at 字段
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为整合方案表创建触发器
CREATE TRIGGER update_recruitment_integrated_updated_at 
    BEFORE UPDATE ON recruitment_process_integrated 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 为分表方案各表创建触发器
CREATE TRIGGER update_recruitment_process_updated_at 
    BEFORE UPDATE ON recruitment_process 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_first_interview_updated_at 
    BEFORE UPDATE ON recruitment_first_interview 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_second_interview_updated_at 
    BEFORE UPDATE ON recruitment_second_interview 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_onboarding_updated_at 
    BEFORE UPDATE ON recruitment_onboarding 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();


-- ============================================
-- 设置行级安全策略 (RLS)
-- ============================================

-- 整合方案表 RLS
ALTER TABLE recruitment_process_integrated ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous select on recruitment_integrated" 
    ON recruitment_process_integrated FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on recruitment_integrated" 
    ON recruitment_process_integrated FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on recruitment_integrated" 
    ON recruitment_process_integrated FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- 分表方案 - 主表 RLS
ALTER TABLE recruitment_process ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous select on recruitment_process" 
    ON recruitment_process FOR SELECT TO anon USING (true);

CREATE POLICY "Allow anonymous insert on recruitment_process" 
    ON recruitment_process FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "Allow anonymous update on recruitment_process" 
    ON recruitment_process FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- 分表方案 - 环节表 RLS
ALTER TABLE recruitment_first_interview ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruitment_second_interview ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruitment_onboarding ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruitment_history ENABLE ROW LEVEL SECURITY;

-- 环节表通用策略
CREATE POLICY "Allow anonymous all on first_interview" 
    ON recruitment_first_interview FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous all on second_interview" 
    ON recruitment_second_interview FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous all on onboarding" 
    ON recruitment_onboarding FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Allow anonymous all on history" 
    ON recruitment_history FOR ALL TO anon USING (true) WITH CHECK (true);


-- ============================================
-- 创建数据同步函数：从 applications 表同步数据
-- ============================================

-- 整合方案：同步函数
CREATE OR REPLACE FUNCTION sync_application_to_integrated(app_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO recruitment_process_integrated (
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
        source_status = EXCLUDED.status,
        updated_at = NOW()
    RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;


-- 分表方案：同步函数
CREATE OR REPLACE FUNCTION sync_application_to_separate(app_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    new_process_id INTEGER;
BEGIN
    INSERT INTO recruitment_process (
        application_id,
        name,
        phone,
        position,
        job_type,
        education,
        experience,
        dynamic_fields,
        source_type,
        is_manual_add
    )
    SELECT 
        a.id,
        a.name,
        a.phone,
        a.position,
        a.job_type,
        a.education,
        a.experience,
        a.dynamic_fields,
        'sync',
        FALSE
    FROM applications a
    WHERE a.id = app_id
    ON CONFLICT (application_id) DO UPDATE SET
        name = EXCLUDED.name,
        phone = EXCLUDED.phone,
        position = EXCLUDED.position,
        job_type = EXCLUDED.job_type,
        education = EXCLUDED.education,
        experience = EXCLUDED.experience,
        dynamic_fields = EXCLUDED.dynamic_fields,
        updated_at = NOW()
    RETURNING id INTO new_process_id;
    
    RETURN new_process_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================
-- 创建手动添加记录的函数
-- ============================================

-- 整合方案：手动添加
CREATE OR REPLACE FUNCTION add_manual_recruitment_integrated(
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
    INSERT INTO recruitment_process_integrated (
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


-- 分表方案：手动添加
CREATE OR REPLACE FUNCTION add_manual_recruitment_separate(
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
    new_process_id INTEGER;
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
    RETURNING id INTO new_process_id;
    
    RETURN new_process_id;
END;
$$ LANGUAGE plpgsql;


-- ============================================
-- 完成提示
-- ============================================
SELECT '招聘流程管理模块数据库表创建完成！' as message;
SELECT '整合方案表：recruitment_process_integrated' as integrated_table;
SELECT '分表方案表：recruitment_process, recruitment_first_interview, recruitment_second_interview, recruitment_onboarding' as separate_tables;
SELECT '共用表：recruitment_history' as history_table;
