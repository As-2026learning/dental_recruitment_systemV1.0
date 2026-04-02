# 义齿工厂招聘系统 - 完整业务流程文档

## 文档信息
- **版本**: 1.0
- **创建日期**: 2026-03-28
- **文档类型**: 业务流程规范
- **适用范围**: 开发团队、产品团队、运维团队

---

## 目录
1. [系统总体架构](#1-系统总体架构)
2. [前端业务流程](#2-前端业务流程)
3. [后端业务流程](#3-后端业务流程)
4. [数据流转机制](#4-数据流转机制)
5. [业务规则与校验](#5-业务规则与校验)
6. [异常处理策略](#6-异常处理策略)
7. [用户体验优化](#7-用户体验优化)

---

## 1. 系统总体架构

### 1.1 系统组件关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                          用户层                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   求职者      │  │   HR专员     │  │   管理员     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
└─────────┼─────────────────┼─────────────────┼──────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                         前端应用层                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 应聘表单页面  │  │ 预约页面      │  │ 后台管理页面  │          │
│  │              │  │              │  │              │          │
│  │ • 岗位选择    │  │ • 日历选择    │  │ • 数据管理    │          │
│  │ • 信息填写    │  │ • 时段选择    │  │ • 配置管理    │          │
│  │ • 表单验证    │  │ • 数据预填充  │  │ • 报表导出    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
└─────────┼─────────────────┼─────────────────┼──────────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │ HTTPS/REST API
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         后端服务层                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ 应聘服务      │  │ 预约服务      │  │ 配置服务      │          │
│  │              │  │              │  │              │          │
│  │ • 数据验证    │  │ • 时段管理    │  │ • 字段配置    │          │
│  │ • 数据存储    │  │ • 容量控制    │  │ • 系统参数    │          │
│  │ • 状态管理    │  │ • 冲突检测    │  │ • 权限控制    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
└─────────┼─────────────────┼─────────────────┼──────────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │ SQL/ORM
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         数据存储层                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  PostgreSQL  │  │  LocalStorage│  │   Session    │          │
│  │  (主数据库)   │  │  (本地缓存)   │  │   (会话)     │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 核心业务实体

| 实体 | 描述 | 关键属性 | 关联关系 |
|------|------|----------|----------|
| Application | 应聘申请 | id, position, name, phone, status | 1:N Booking |
| Booking | 面试预约 | id, application_id, date, slot, status | N:1 Application |
| FieldConfig | 字段配置 | id, name, label, type, required | N:M Template |
| Template | 表单模板 | id, name, description, is_active | M:N FieldConfig |
| Position | 招聘岗位 | id, name, description, is_active | 1:N Application |
| TimeSlot | 预约时段 | id, key, label, capacity, is_active | 1:N Booking |

---

## 2. 前端业务流程

### 2.1 应聘表单页面 (candidate-form-complete.html)

#### 2.1.1 页面加载流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   开始      │────>│  加载SDK    │────>│ 初始化配置  │────>│  加载字段   │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                    │
                              ┌─────────────────────────────────────┘
                              │
                              ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  渲染完成   │<────│  渲染表单   │<────│  绑定事件   │<────│  验证配置   │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

**详细步骤**:

1. **SDK加载阶段**
   ```javascript
   // 动态加载Supabase SDK，支持多CDN源
   function loadSupabaseSDK() {
       return new Promise((resolve, reject) => {
           const script = document.createElement('script');
           script.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
           script.onload = resolve;
           script.onerror = () => {
               // 备用CDN
               script.src = 'https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.min.js';
           };
           document.head.appendChild(script);
       });
   }
   ```

2. **初始化配置**
   ```javascript
   // 配置信息
   const supabaseUrl = 'https://dxrghlqnwfwpuxjvyisv.supabase.co';
   const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   
   // 创建客户端
   supabase = window.supabase.createClient(supabaseUrl, supabaseKey);
   ```

3. **字段加载策略（三层降级）**
   ```
   第一层: 从数据库加载模板字段
       ↓ (失败或无数据)
   第二层: 从localStorage加载缓存字段
       ↓ (失败或无数据)
   第三层: 使用默认字段配置
   ```

#### 2.1.2 岗位选择流程

```
用户选择岗位
    │
    ▼
┌─────────────┐
│ 确定模板ID  │
│ (学徒/普工) │─> templateId = 1 (基础模板)
│ (技术岗位)  │─> templateId = 2 (技术模板)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载字段配置 │
└──────┬──────┘
       │
       ├── 尝试从数据库加载
       ├── 尝试从localStorage加载
       └── 使用默认字段
       │
       ▼
┌─────────────┐
│ 渲染动态表单 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 绑定验证事件 │
└─────────────┘
```

**代码实现**:
```javascript
async function handlePositionChange() {
    const position = document.getElementById('position').value;
    
    // 确定模板ID
    const templateId = (position === '学徒' || position === '普工') ? 1 : 2;
    
    // 三层加载策略
    let fields = await loadFieldsFromDatabase(templateId);
    if (!fields) fields = loadFieldsFromLocalStorage(templateId);
    if (!fields) fields = (templateId === 1) ? defaultBaseFields : defaultTechFields;
    
    // 渲染表单
    renderDynamicFields(container, fields);
    
    // 绑定事件
    bindFieldEvents();
}
```

#### 2.1.3 表单验证流程

```
用户输入
    │
    ▼
┌─────────────────────────────────────┐
│         实时验证触发器               │
│  • input事件  • change事件  • blur事件 │
└─────────────────┬───────────────────┘
                  │
                  ▼
        ┌─────────────────┐
        │   字段类型判断   │
        └────────┬────────┘
                 │
       ┌─────────┼─────────┐
       ▼         ▼         ▼
   ┌───────┐ ┌───────┐ ┌───────┐
   │文本字段│ │数字字段│ │选择字段│
   └───┬───┘ └───┬───┘ └───┬───┘
       │         │         │
       ▼         ▼         ▼
   ┌─────────────────────────────────┐
   │         验证规则引擎             │
   │  ┌───────────────────────────┐  │
   │  │ 必填验证: 检查是否为空      │  │
   │  │ 格式验证: 正则表达式匹配    │  │
   │  │ 范围验证: 最小/最大值检查   │  │
   │  │ 长度验证: 字符数限制       │  │
   │  └───────────────────────────┘  │
   └───────────────┬─────────────────┘
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
    ┌──────────┐       ┌──────────┐
    │ 验证通过  │       │ 验证失败  │
    │ 清除错误  │       │ 显示错误  │
    │ 更新进度  │       │ 阻止提交  │
    └──────────┘       └──────────┘
```

**验证规则实现**:
```javascript
function validateField(input) {
    const fieldGroup = input.closest('.form-group');
    const fieldId = fieldGroup.getAttribute('data-field-id');
    const field = currentFields.find(f => f.id == fieldId);
    
    let isValid = false;
    let errorMessage = '';
    
    switch (field.field_name) {
        case 'phone':
            // 中国大陆手机号验证
            if (!/^1[3-9]\d{9}$/.test(value)) {
                isValid = false;
                errorMessage = '请输入正确的手机号码（11位数字）';
            }
            break;
            
        case 'age':
            // 年龄范围验证
            const age = parseInt(value);
            if (isNaN(age) || age < 16 || age > 65) {
                isValid = false;
                errorMessage = '请输入有效的年龄（16-65岁）';
            }
            break;
            
        case 'name':
            // 姓名长度验证
            if (value.length < 2 || value.length > 20) {
                isValid = false;
                errorMessage = '姓名长度应在2-20个字符之间';
            }
            break;
    }
    
    // 更新UI状态
    updateValidationUI(fieldGroup, isValid, errorMessage);
    
    return isValid;
}
```

#### 2.1.4 表单提交流程

```
用户点击提交
    │
    ▼
┌─────────────┐
│ 阻止默认行为 │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│ 全表单验证   │────>│ 验证失败?   │──Yes──> 显示错误提示
└──────┬──────┘     └─────────────┘
       │ No
       ▼
┌─────────────┐
│ 收集表单数据 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 显示加载状态 │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│         数据保存策略                 │
│  ┌───────────────────────────────┐  │
│  │ 第一层: 保存到Supabase数据库   │  │
│  │     (重试3次)                 │  │
│  │         ↓                     │  │
│  │ 第二层: 保存到localStorage    │  │
│  │     (备用方案)                │  │
│  └───────────────────────────────┘  │
└─────────────────┬───────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
   ┌──────────┐       ┌──────────┐
   │ 保存成功  │       │ 保存失败  │
   │          │       │          │
   │ • 保存到  │       │ • 显示错误 │
   │   localStorage   │ • 允许重试 │
   │ • 跳转预约 │       │          │
   │   页面    │       │          │
   └──────────┘       └──────────┘
```

**提交处理代码**:
```javascript
async function submitForm(e) {
    e.preventDefault();
    
    // 验证表单
    if (!validateForm()) {
        showError('请填写所有必填项');
        return;
    }
    
    // 收集数据
    const formData = collectFormData();
    
    // 显示加载状态
    showLoadingState();
    
    let savedApplication = null;
    
    // 尝试保存到数据库（最多重试3次）
    if (initSupabase()) {
        for (let attempt = 1; attempt <= 3; attempt++) {
            try {
                const dbRecord = prepareDatabaseRecord(formData);
                const result = await supabase
                    .from('applications')
                    .insert([dbRecord])
                    .select();
                
                if (result.data && result.data.length > 0) {
                    savedApplication = result.data[0];
                    break;
                }
            } catch (error) {
                if (attempt < 3) await delay(1000);
            }
        }
    }
    
    // 如果数据库保存失败，使用本地存储
    if (!savedApplication) {
        savedApplication = saveToLocalStorage(formData);
    }
    
    // 保存个人信息到localStorage，用于预约页面
    localStorage.setItem('candidateProfile', JSON.stringify({
        name: formData.fields.name,
        phone: formData.fields.phone,
        position: formData.position
    }));
    
    // 跳转到预约页面
    redirectToBookingPage(savedApplication.id, formData);
}
```

### 2.2 面试预约页面 (booking.html)

#### 2.2.1 页面初始化流程

```
页面加载
    │
    ▼
┌─────────────┐
│ 显示加载动画 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 动态加载SDK  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 初始化Supabase│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载系统配置 │
│ • 岗位列表   │
│ • 时段配置   │
│ • 预约须知   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 初始化日历   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载应聘数据 │
│ (URL参数/    │
│  localStorage)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 预填充表单   │
│ • 姓名       │
│ • 电话       │
│ • 岗位       │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 隐藏加载动画 │
└─────────────┘
```

**数据加载策略**:
```javascript
function loadApplicationData() {
    // 1. 从URL参数获取数据
    const params = new URLSearchParams(window.location.search);
    const urlName = params.get('name');
    const urlPhone = params.get('phone');
    const urlPosition = params.get('position');
    
    // 2. 从localStorage获取数据
    const candidateProfile = localStorage.getItem('candidateProfile');
    const profileData = candidateProfile ? JSON.parse(candidateProfile) : {};
    
    // 3. 合并数据（URL参数优先）
    const name = urlName || profileData.name || '';
    const phone = urlPhone || profileData.phone || '';
    const position = urlPosition || profileData.position || '';
    
    // 4. 填充表单
    fillFormFields(name, phone, position);
}
```

#### 2.2.2 日历选择流程

```
用户点击日期
    │
    ▼
┌─────────────┐
│ 验证日期可用性│
│ • 是否工作日  │
│ • 是否已过期  │
│ • 是否可预约  │
└──────┬──────┘
       │
       ├── 不可用 ──> 显示禁用状态
       │
       ▼ 可用
┌─────────────┐
│ 高亮选中日期 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载时段列表 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 查询已预约数 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 计算剩余容量 │
│ 并渲染时段   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 绑定时段点击 │
└─────────────┘
```

**时段容量计算**:
```javascript
async function loadTimeSlots(dateStr) {
    // 查询已预约数量
    const result = await db.from('bookings')
        .select('time_slot')
        .eq('booking_date', dateStr)
        .neq('status', 'cancelled');
    
    // 统计每个时段的预约数
    const counts = {};
    result.data.forEach(booking => {
        counts[booking.time_slot] = (counts[booking.time_slot] || 0) + 1;
    });
    
    // 渲染时段，显示剩余容量
    timeSlots.forEach(slot => {
        const booked = counts[slot.slot_key] || 0;
        const available = slot.capacity - booked;
        renderTimeSlot(slot, available);
    });
}
```

#### 2.2.3 预约提交流程

```
用户点击提交预约
    │
    ▼
┌─────────────┐
│ 表单验证    │
│ • 姓名必填  │
│ • 电话格式  │
│ • 日期选择  │
│ • 时段选择  │
└──────┬──────┘
       │
       ├── 验证失败 ──> 显示错误提示
       │
       ▼ 验证通过
┌─────────────┐
│ 检查重复预约│
│ (同电话同日 │
│  同时段)    │
└──────┬──────┘
       │
       ├── 已存在 ──> 提示已预约
       │
       ▼ 未预约
┌─────────────┐
│ 查找关联的  │
│ 应聘信息    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 创建预约记录│
│ • 关联应聘ID│
│ • 保存预约  │
│   信息      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 跳转到成功  │
│ 页面        │
└─────────────┘
```

### 2.3 后台管理页面 (applications.html)

#### 2.3.1 页面初始化流程

```
页面加载
    │
    ▼
┌─────────────┐
│ 显示加载动画 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载SDK并   │
│ 初始化      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 检查用户认证 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载岗位列表 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载统计数据 │
│ • 总应聘数   │
│ • 待处理数   │
│ • 总预约数   │
│ • 今日预约   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 加载应聘列表 │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 隐藏加载动画 │
└─────────────┘
```

#### 2.3.2 数据加载与关联流程

```
加载应聘数据
    │
    ▼
┌─────────────────────────────┐
│ 从applications表查询数据     │
│ • 应用筛选条件               │
│ • 应用排序规则               │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 从bookings表查询所有预约     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      数据关联处理            │
│  ┌─────────────────────┐    │
│  │ 关联策略:            │    │
│  │ 1. 通过application_id│    │
│  │    直接关联          │    │
│  │ 2. 通过phone号码     │    │
│  │    间接关联          │    │
│  └─────────────────────┘    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 应用搜索筛选                 │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 渲染数据表格                 │
│ • 应聘信息                   │
│ • 关联的预约信息             │
│ • 操作按钮                   │
└─────────────────────────────┘
```

**数据关联实现**:
```javascript
async function loadApplications() {
    // 加载应聘信息
    const appResult = await db.from('applications').select('*');
    
    // 加载预约信息
    const bookingsResult = await db.from('bookings').select('*');
    
    // 合并数据
    const applicationsWithBooking = appResult.data.map(app => {
        // 通过application_id关联
        let bookings = bookingsResult.data.filter(b => 
            b.application_id === app.id
        );
        
        // 如果没有直接关联，通过电话关联
        if (bookings.length === 0 && app.phone) {
            bookings = bookingsResult.data.filter(b => 
                b.phone === app.phone
            );
        }
        
        // 取最新的预约
        const booking = bookings.length > 0 
            ? bookings.sort((a, b) => 
                new Date(b.created_at) - new Date(a.created_at)
              )[0]
            : null;
        
        return { ...app, booking };
    });
    
    renderApplications(applicationsWithBooking);
}
```

---

## 3. 后端业务流程

### 3.1 接口设计规范

#### 3.1.1 RESTful API设计原则

| 原则 | 说明 | 示例 |
|------|------|------|
| 资源导向 | URL表示资源 | `/applications`, `/bookings` |
| HTTP方法 | 操作资源 | GET(查询), POST(创建), PUT(更新), DELETE(删除) |
| 状态码 | 标准HTTP状态码 | 200(成功), 201(创建), 400(错误), 401(未授权), 500(服务器错误) |
| 版本控制 | API版本管理 | `/v1/applications` |
| 过滤排序 | 查询参数 | `?status=eq.pending&order=created_at.desc` |

#### 3.1.2 接口列表

**应聘管理接口**

| 方法 | 路径 | 描述 | 请求参数 | 响应数据 |
|------|------|------|----------|----------|
| GET | /applications | 查询应聘列表 | status, position, order | Application[] |
| POST | /applications | 创建应聘记录 | Application对象 | Application |
| GET | /applications/:id | 查询应聘详情 | id | Application |
| PUT | /applications/:id | 更新应聘信息 | id, 更新字段 | Application |
| DELETE | /applications/:id | 删除应聘记录 | id | 空 |

**预约管理接口**

| 方法 | 路径 | 描述 | 请求参数 | 响应数据 |
|------|------|------|----------|----------|
| GET | /bookings | 查询预约列表 | date, status, order | Booking[] |
| POST | /bookings | 创建预约 | Booking对象 | Booking |
| PUT | /bookings/:id | 更新预约状态 | id, status | Booking |
| GET | /bookings/availability | 查询时段可用性 | date | Availability[] |

### 3.2 数据处理流程

#### 3.2.1 应聘数据处理

```
接收应聘请求
    │
    ▼
┌─────────────────────────────┐
│       请求验证层             │
│  • Content-Type检查         │
│  • 请求体格式验证            │
│  • 必填字段检查              │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       业务规则校验           │
│  • 手机号格式验证            │
│  • 年龄范围验证(16-65)       │
│  • 岗位有效性验证            │
│  • 重复提交检查              │
└──────────────┬──────────────┘
               │
               ├── 验证失败 ──> 返回400错误
               │
               ▼ 验证通过
┌─────────────────────────────┐
│       数据转换处理           │
│  • JSON数据解析              │
│  • 字段映射转换              │
│  • 默认值设置                │
│  • 时间戳生成                │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       数据持久化             │
│  • 开启事务                  │
│  • 插入applications表        │
│  • 提交事务                  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       响应处理               │
│  • 构建响应数据              │
│  • 设置HTTP状态码(201)       │
│  • 返回创建的记录            │
└─────────────────────────────┘
```

#### 3.2.2 预约数据处理

```
接收预约请求
    │
    ▼
┌─────────────────────────────┐
│       请求验证层             │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       业务规则校验           │
│  • 日期有效性(未来日期)      │
│  • 时段有效性                │
│  • 容量检查                  │
│  • 重复预约检查              │
└──────────────┬──────────────┘
               │
               ├── 验证失败 ──> 返回400错误
               │
               ▼ 验证通过
┌─────────────────────────────┐
│       关联数据处理           │
│  • 查找关联的应聘信息        │
│  • 建立application_id关联    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       数据持久化             │
│  • 开启事务                  │
│  • 插入bookings表            │
│  • 提交事务                  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│       响应处理               │
│  • 返回201状态码             │
│  • 返回预约记录              │
└─────────────────────────────┘
```

### 3.3 业务规则校验

#### 3.3.1 应聘业务规则

| 规则ID | 规则描述 | 校验逻辑 | 错误提示 |
|--------|----------|----------|----------|
| APP-001 | 姓名必填 | `name != null && name.length > 0` | 请输入姓名 |
| APP-002 | 姓名长度 | `name.length >= 2 && name.length <= 20` | 姓名长度应在2-20个字符之间 |
| APP-003 | 手机号格式 | `/^1[3-9]\d{9}$/.test(phone)` | 请输入正确的手机号码（11位数字） |
| APP-004 | 年龄范围 | `age >= 16 && age <= 65` | 请输入有效的年龄（16-65岁） |
| APP-005 | 岗位必填 | `position != null` | 请选择应聘岗位 |
| APP-006 | 防重复提交 | 同一手机号24小时内只能提交一次 | 您已提交过应聘信息 |

#### 3.3.2 预约业务规则

| 规则ID | 规则描述 | 校验逻辑 | 错误提示 |
|--------|----------|----------|----------|
| BOK-001 | 日期有效性 | `booking_date >= today` | 请选择有效的面试日期 |
| BOK-002 | 工作日限制 | `dayOfWeek >= 1 && dayOfWeek <= 5` | 只能选择工作日 |
| BOK-003 | 提前时间 | `booking_date > today || (today && currentHour < 15)` | 请提前至少2小时预约 |
| BOK-004 | 时段容量 | `bookedCount < capacity` | 该时段已满，请选择其他时段 |
| BOK-005 | 防重复预约 | 同一手机号同日同时段只能预约一次 | 您已在该时段预约过面试 |
| BOK-006 | 时段有效性 | `time_slot in validSlots` | 请选择有效的面试时段 |

### 3.4 权限控制机制

#### 3.4.1 角色定义

| 角色 | 权限范围 | 操作权限 |
|------|----------|----------|
| 匿名用户 | 前端页面 | 提交应聘、创建预约、查询预约 |
| HR专员 | 后台管理 | 查看数据、更新状态、导出报表 |
| 系统管理员 | 全部功能 | 所有操作 + 系统配置 |

#### 3.4.2 权限控制实现

```javascript
// 基于Supabase RLS的权限控制

// 1. 应聘表权限策略
CREATE POLICY "允许匿名提交应聘" ON applications
    FOR INSERT TO anon
    WITH CHECK (true);

CREATE POLICY "允许HR查看所有应聘" ON applications
    FOR SELECT TO authenticated
    USING (auth.role() = 'hr' OR auth.role() = 'admin');

CREATE POLICY "允许HR更新应聘状态" ON applications
    FOR UPDATE TO authenticated
    USING (auth.role() IN ('hr', 'admin'));

// 2. 预约表权限策略
CREATE POLICY "允许匿名创建预约" ON bookings
    FOR INSERT TO anon
    WITH CHECK (true);

CREATE POLICY "允许HR管理预约" ON bookings
    FOR ALL TO authenticated
    USING (auth.role() IN ('hr', 'admin'));

// 3. 配置表权限策略
CREATE POLICY "仅管理员可修改配置" ON field_configs
    FOR ALL TO authenticated
    USING (auth.role() = 'admin');
```

### 3.5 异常处理策略

#### 3.5.1 异常分类

| 异常类型 | 描述 | 处理方式 | HTTP状态码 |
|----------|------|----------|------------|
| 验证异常 | 输入数据不符合规则 | 返回具体错误信息 | 400 |
| 认证异常 | 用户未登录或权限不足 | 提示登录或权限不足 | 401/403 |
| 资源异常 | 资源不存在或已删除 | 返回资源不存在 | 404 |
| 冲突异常 | 数据冲突（重复预约等） | 返回冲突信息 | 409 |
| 服务器异常 | 数据库错误、系统错误 | 记录日志，返回通用错误 | 500 |

#### 3.5.2 异常处理流程

```
执行业务逻辑
    │
    ▼
┌─────────────────────────────┐
│       try-catch包裹          │
└──────────────┬──────────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
   ┌───────┐     ┌───────────┐
   │ 成功   │     │ 捕获异常   │
   └───┬───┘     └─────┬─────┘
       │               │
       │               ▼
       │       ┌───────────────┐
       │       │ 异常类型判断   │
       │       └───────┬───────┘
       │               │
       │       ┌───────┼───────┐
       │       ▼       ▼       ▼
       │   ┌──────┐ ┌──────┐ ┌──────┐
       │   │验证  │ │资源  │ │系统  │
       │   │异常  │ │异常  │ │异常  │
       │   └──┬───┘ └──┬───┘ └──┬───┘
       │      │        │        │
       │      ▼        ▼        ▼
       │  ┌───────────────────────────┐
       │  │      错误响应构建          │
       │  │  • 错误码                  │
       │  │  • 错误信息                │
       │  │  • 详细信息                │
       │  │  • 时间戳                  │
       │  └───────────────────────────┘
       │               │
       └───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │   返回响应     │
               └───────────────┘
```

**异常处理代码示例**:
```javascript
async function handleRequest(req, res) {
    try {
        // 执行业务逻辑
        const result = await businessLogic(req.body);
        res.status(200).json({
            success: true,
            data: result,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        // 异常分类处理
        let statusCode = 500;
        let errorCode = 'INTERNAL_ERROR';
        let message = '系统内部错误';
        
        if (error.name === 'ValidationError') {
            statusCode = 400;
            errorCode = 'VALIDATION_ERROR';
            message = error.message;
        } else if (error.name === 'NotFoundError') {
            statusCode = 404;
            errorCode = 'RESOURCE_NOT_FOUND';
            message = '请求的资源不存在';
        } else if (error.name === 'ConflictError') {
            statusCode = 409;
            errorCode = 'RESOURCE_CONFLICT';
            message = error.message;
        }
        
        // 记录错误日志
        logger.error({
            code: errorCode,
            message: error.message,
            stack: error.stack,
            request: req.body
        });
        
        // 返回错误响应
        res.status(statusCode).json({
            success: false,
            error: {
                code: errorCode,
                message: message,
                details: error.details || []
            },
            timestamp: new Date().toISOString()
        });
    }
}
```

---

## 4. 数据流转机制

### 4.1 数据同步策略

#### 4.1.1 三层数据存储架构

```
┌─────────────────────────────────────────────────────────────┐
│                      数据同步架构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              第一层: 云端数据库                       │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ PostgreSQL   │  │  Supabase    │                │   │
│  │  │ 主数据库      │  │  实时同步    │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  │  • 数据持久化存储                                   │   │
│  │  • 多设备数据共享                                   │   │
│  │  • 数据备份恢复                                     │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │ 网络同步                        │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              第二层: 本地存储                        │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ localStorage │  │ sessionStorage│               │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  │  • 临时数据缓存                                     │   │
│  │  • 页面间数据传递                                   │   │
│  │  • 离线数据存储                                     │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │ 内存同步                        │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              第三层: 应用内存                        │   │
│  │  ┌──────────────┐  ┌──────────────┐                │   │
│  │  │ JavaScript   │  │  Vue/React   │                │   │
│  │  │ 变量/对象    │  │  State       │                │   │
│  │  └──────────────┘  └──────────────┘                │   │
│  │  • 运行时数据                                       │   │
│  │  • 页面状态管理                                     │   │
│  │  • 临时计算结果                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 4.1.2 数据同步流程

**应聘数据同步**:
```
用户提交应聘表单
    │
    ▼
┌─────────────────────────────┐
│ 1. 验证数据                  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. 保存到云端数据库          │
│    (Supabase)               │
│    • 主数据存储              │
│    • 返回记录ID              │
└──────────────┬──────────────┘
               │
               ├── 保存成功 ──┐
               │              │
               ▼              │
┌─────────────────────────────┐│
│ 3. 备份到本地存储            ││
│    (localStorage)           ││
│    • candidateProfile       ││
│    • currentApplication     ││
└──────────────┬──────────────┘│
               │               │
               ▼               │
┌─────────────────────────────┐│
│ 4. 同步到预约页面            ││
│    • URL参数传递            ││
│    • localStorage读取       ││
└─────────────────────────────┘│
               │               │
               ▼               │
        ┌──────────────┐       │
        │ 保存失败?    │       │
        └──────┬───────┘       │
               │ Yes           │
               ▼               │
┌─────────────────────────────┐│
│ 备用方案: 仅保存到本地       ││
│ • 标记为"local_"前缀        ││
│ • 提示用户网络问题          ││
│ • 后续手动同步              ││
└─────────────────────────────┘
```

### 4.2 数据一致性保障

#### 4.2.1 一致性策略

| 场景 | 策略 | 实现方式 |
|------|------|----------|
| 实时一致性 | 强一致性 | 数据库事务、乐观锁 |
| 最终一致性 | 异步同步 | 定时任务、消息队列 |
| 离线一致性 | 本地优先 | localStorage缓存、冲突检测 |

#### 4.2.2 冲突解决机制

```
检测到数据冲突
    │
    ▼
┌─────────────────────────────┐
│ 冲突类型判断                 │
└──────────────┬──────────────┘
               │
       ┌───────┴───────┐
       ▼               ▼
   ┌───────┐     ┌───────────┐
   │ 时间戳 │     │ 业务规则   │
   │ 冲突   │     │ 冲突      │
   └───┬───┘     └─────┬─────┘
       │               │
       ▼               ▼
┌──────────────┐ ┌──────────────┐
│ 取最新时间戳  │ │ 根据业务规则 │
│ 的数据       │ │ 判断优先级   │
└──────────────┘ └──────────────┘
       │               │
       └───────┬───────┘
               │
               ▼
┌─────────────────────────────┐
│ 合并数据                     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 更新所有存储层               │
└─────────────────────────────┘
```

---

## 5. 业务规则与校验

### 5.1 前端校验规则

#### 5.1.1 实时校验触发时机

| 触发事件 | 校验类型 | 说明 |
|----------|----------|------|
| input | 格式校验 | 用户输入时实时检查格式 |
| change | 完整校验 | 字段值变化时进行完整验证 |
| blur | 必填校验 | 失去焦点时检查必填项 |
| submit | 全量校验 | 提交时验证所有字段 |

#### 5.1.2 校验规则配置

```javascript
const validationRules = {
    name: {
        required: true,
        minLength: 2,
        maxLength: 20,
        pattern: /^[\u4e00-\u9fa5a-zA-Z\s]+$/,
        message: '姓名只能包含中文、英文字母和空格'
    },
    phone: {
        required: true,
        pattern: /^1[3-9]\d{9}$/,
        message: '请输入正确的手机号码（11位数字）'
    },
    age: {
        required: true,
        type: 'number',
        min: 16,
        max: 65,
        message: '年龄必须在16-65岁之间'
    },
    email: {
        required: false,
        pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
        message: '请输入正确的邮箱地址'
    }
};
```

### 5.2 后端校验规则

#### 5.2.1 数据库约束

```sql
-- 应聘表约束
ALTER TABLE applications ADD CONSTRAINT 
    chk_age_range CHECK (age >= 16 AND age <= 65);

ALTER TABLE applications ADD CONSTRAINT 
    chk_phone_format CHECK (phone ~ '^1[3-9]\d{9}$');

ALTER TABLE applications ADD CONSTRAINT 
    chk_name_length CHECK (LENGTH(name) >= 2 AND LENGTH(name) <= 20);

-- 预约表约束
ALTER TABLE bookings ADD CONSTRAINT 
    chk_future_date CHECK (booking_date >= CURRENT_DATE);

ALTER TABLE bookings ADD CONSTRAINT 
    chk_valid_status CHECK (status IN ('pending', 'confirmed', 'cancelled'));
```

#### 5.2.2 业务逻辑校验

```javascript
// 预约时段容量检查
async function checkSlotAvailability(date, slot, capacity) {
    const result = await db.from('bookings')
        .select('id', { count: 'exact' })
        .eq('booking_date', date)
        .eq('time_slot', slot)
        .neq('status', 'cancelled');
    
    const bookedCount = result.count;
    return {
        available: bookedCount < capacity,
        remaining: capacity - bookedCount,
        total: capacity
    };
}

// 重复预约检查
async function checkDuplicateBooking(phone, date, slot) {
    const result = await db.from('bookings')
        .select('id')
        .eq('phone', phone)
        .eq('booking_date', date)
        .eq('time_slot', slot)
        .neq('status', 'cancelled')
        .single();
    
    return result.data !== null;
}
```

---

## 6. 异常处理策略

### 6.1 前端异常处理

#### 6.1.1 异常分类与处理

| 异常类型 | 示例 | 处理方式 | 用户提示 |
|----------|------|----------|----------|
| 网络异常 | 请求超时、断网 | 重试3次，后转本地存储 | "网络不稳定，已保存到本地" |
| 验证异常 | 格式错误、必填缺失 | 实时显示错误信息 | 具体字段错误提示 |
| 服务器异常 | 500错误 | 记录日志，友好提示 | "系统繁忙，请稍后重试" |
| 业务异常 | 时段已满 | 显示具体业务错误 | "该时段已满，请选择其他时段" |

#### 6.1.2 全局异常处理

```javascript
// 全局错误处理
window.addEventListener('error', (event) => {
    logger.error({
        type: 'global_error',
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error?.stack
    });
    
    // 显示友好错误提示
    showGlobalError('系统出现错误，请刷新页面重试');
});

// Promise异常处理
window.addEventListener('unhandledrejection', (event) => {
    logger.error({
        type: 'unhandled_promise_rejection',
        reason: event.reason
    });
    
    event.preventDefault();
});
```

### 6.2 后端异常处理

#### 6.2.1 异常处理中间件

```javascript
// 错误处理中间件
app.use((err, req, res, next) => {
    // 记录错误日志
    logger.error({
        error: err.message,
        stack: err.stack,
        url: req.url,
        method: req.method,
        body: req.body,
        user: req.user?.id
    });
    
    // 根据环境返回不同信息
    const isDevelopment = process.env.NODE_ENV === 'development';
    
    res.status(err.status || 500).json({
        success: false,
        error: {
            code: err.code || 'INTERNAL_ERROR',
            message: err.message || '系统内部错误',
            ...(isDevelopment && { stack: err.stack })
        },
        timestamp: new Date().toISOString()
    });
});
```

---

## 7. 用户体验优化

### 7.1 交互设计优化

#### 7.1.1 加载状态管理

```
用户操作
    │
    ▼
┌─────────────────────────────┐
│ 立即显示加载状态             │
│ • 按钮禁用                   │
│ • 显示加载动画               │
│ • 进度条(长时间操作)         │
└──────────────┬──────────────┘
               │
               ▼
         ┌──────────────┐
         │  执行操作     │
         └──────┬───────┘
                │
        ┌───────┴───────┐
        ▼               ▼
   ┌──────────┐   ┌──────────┐
   │ 成功     │   │ 失败     │
   │          │   │          │
   │ • 成功   │   │ • 错误   │
   │   提示   │   │   提示   │
   │ • 状态   │   │ • 重试   │
   │   更新   │   │   按钮   │
   │ • 自动   │   │ • 恢复   │
   │   跳转   │   │   状态   │
   └──────────┘   └──────────┘
```

#### 7.1.2 表单交互优化

| 优化项 | 实现方式 | 效果 |
|--------|----------|------|
| 自动保存 | 定时保存到localStorage | 防止数据丢失 |
| 智能提示 | 输入时显示格式示例 | 减少输入错误 |
| 实时验证 | 输入时即时验证 | 及时反馈 |
| 渐进展示 | 根据选择动态显示字段 | 减少认知负担 |
| 一键清除 | 提供清除按钮 | 方便重新输入 |

### 7.2 性能优化

#### 7.2.1 加载优化

| 优化策略 | 实现方式 | 预期效果 |
|----------|----------|----------|
| 懒加载 | 按需加载组件和数据 | 减少初始加载时间 |
| 缓存策略 | localStorage缓存配置 | 减少重复请求 |
| CDN加速 | 使用CDN加载静态资源 | 提高资源加载速度 |
| 代码分割 | 按路由分割代码 | 减少主包大小 |
| 图片优化 | 压缩、WebP格式 | 减少图片加载时间 |

#### 7.2.2 渲染优化

```javascript
// 虚拟滚动（大数据列表）
function VirtualList({ items, itemHeight, renderItem }) {
    const [scrollTop, setScrollTop] = useState(0);
    const containerHeight = 400;
    
    const visibleCount = Math.ceil(containerHeight / itemHeight);
    const startIndex = Math.floor(scrollTop / itemHeight);
    const endIndex = Math.min(startIndex + visibleCount, items.length);
    
    const visibleItems = items.slice(startIndex, endIndex);
    
    return (
        <div 
            style={{ height: containerHeight, overflow: 'auto' }}
            onScroll={(e) => setScrollTop(e.target.scrollTop)}
        >
            <div style={{ height: items.length * itemHeight }}>
                <div style={{ transform: `translateY(${startIndex * itemHeight}px)` }}>
                    {visibleItems.map(renderItem)}
                </div>
            </div>
        </div>
    );
}
```

### 7.3 错误处理优化

#### 7.3.1 错误提示设计

| 错误类型 | 提示方式 | 示例 |
|----------|----------|------|
| 输入错误 | 字段级提示 | 输入框下方显示红色错误信息 |
| 提交错误 | 全局提示 | 页面顶部显示错误通知条 |
| 网络错误 | 模态框提示 | 居中显示重试对话框 |
| 系统错误 | 友好页面 | 显示错误代码和联系信息 |

#### 7.3.2 恢复机制

```javascript
// 自动重试机制
async function fetchWithRetry(url, options, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            const response = await fetch(url, options);
            if (response.ok) return response;
            
            // 如果是服务器错误，继续重试
            if (response.status >= 500) {
                throw new Error(`Server error: ${response.status}`);
            }
            
            // 客户端错误，不重试
            return response;
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            
            // 指数退避
            await delay(Math.pow(2, i) * 1000);
        }
    }
}
```

---

## 附录

### A. 业务流程图汇总

#### A.1 完整业务流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      招聘系统完整业务流程                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐                                                  │
│  │ 求职者    │                                                  │
│  └────┬─────┘                                                  │
│       │ 1. 访问应聘页面                                         │
│       ▼                                                         │
│  ┌──────────┐     ┌──────────┐                                 │
│  │ 选择岗位  │────>│ 填写信息  │                                 │
│  └──────────┘     └────┬─────┘                                 │
│                        │ 2. 提交应聘                            │
│                        ▼                                        │
│                 ┌──────────┐                                   │
│                 │ 系统验证  │                                   │
│                 └────┬─────┘                                   │
│                      │ 3. 保存数据                              │
│                      ▼                                          │
│               ┌──────────────┐                                 │
│               │ 数据库+本地   │                                 │
│               └──────┬───────┘                                 │
│                      │ 4. 跳转预约                              │
│                      ▼                                          │
│               ┌──────────┐                                     │
│               │ 选择日期  │────>┌──────────┐                   │
│               └──────────┘     │ 选择时段  │                   │
│                                └────┬─────┘                   │
│                                     │ 5. 提交预约              │
│                                     ▼                          │
│                              ┌──────────┐                     │
│                              │ 系统验证  │                     │
│                              └────┬─────┘                     │
│                                   │ 6. 保存预约               │
│                                   ▼                            │
│                            ┌──────────┐                       │
│                            │ 预约成功  │                       │
│                            └──────────┘                       │
│                                                                 │
│       ┌──────────────────────────────────────┐                 │
│       │                                      │                 │
│       ▼                                      ▼                 │
│  ┌──────────┐                          ┌──────────┐           │
│  │ HR查看   │                          │ 管理配置 │           │
│  │ 应聘信息  │                          │ 字段/时段 │           │
│  └──────────┘                          └──────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### B. 状态管理规范

#### B.1 应用状态定义

```typescript
// 全局状态接口
interface AppState {
    // 用户状态
    user: {
        id: string | null;
        role: 'anonymous' | 'hr' | 'admin';
        isAuthenticated: boolean;
    };
    
    // 应聘状态
    application: {
        current: Application | null;
        list: Application[];
        loading: boolean;
        error: Error | null;
    };
    
    // 预约状态
    booking: {
        current: Booking | null;
        list: Booking[];
        availability: Map<string, number>;
        loading: boolean;
        error: Error | null;
    };
    
    // 配置状态
    config: {
        fields: FieldConfig[];
        templates: Template[];
        timeSlots: TimeSlot[];
        loading: boolean;
    };
    
    // UI状态
    ui: {
        theme: 'light' | 'dark';
        sidebarOpen: boolean;
        modalOpen: boolean;
        notifications: Notification[];
    };
}
```

## 9. 应聘信息登记字段设置

### 9.1 字段管理功能概述

应聘信息登记字段设置功能允许管理员通过系统设置页面对前端应聘表单的字段进行管理，包括字段的添加、编辑、删除和查询等操作。该功能支持多种字段类型，如文本输入、多行文本、数字、下拉选择、单选按钮、复选框和日期等。

### 9.2 字段管理业务流程

#### 9.2.1 字段添加流程

```
┌─────────────────────────────────────────────────────┐
│                 字段添加流程                          │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│           进入系统设置页面                            │
│  ┌──────────────┐  ┌──────────────┐                │
│  │ 点击模板管理  │  │ 选择目标模板  │                │
│  └──────┬───────┘  └──────┬───────┘                │
│         │                 │                         │
│         └────────┬────────┘                         │
│                  │                                  │
│                  ▼                                  │
│  ┌─────────────────────────────────────┐            │
│  │         点击添加字段按钮                │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         填写字段信息                  │            │
│  │  • 字段名称                          │            │
│  │  • 字段标签                          │            │
│  │  • 字段类型                          │            │
│  │  • 必填设置                          │            │
│  │  • 默认值                            │            │
│  │  • 验证规则                          │            │
│  │  • 选项（如适用）                    │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         保存字段配置                  │            │
│  │  • 保存到数据库                      │            │
│  │  • 保存到本地存储（备用）            │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         刷新字段列表                  │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         实时预览更新                  │            │
│  └─────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

#### 9.2.2 字段编辑流程

```
┌─────────────────────────────────────────────────────┐
│                 字段编辑流程                          │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│           进入系统设置页面                            │
│  ┌──────────────┐  ┌──────────────┐                │
│  │ 点击模板管理  │  │ 选择目标模板  │                │
│  └──────┬───────┘  └──────┬───────┘                │
│         │                 │                         │
│         └────────┬────────┘                         │
│                  │                                  │
│                  ▼                                  │
│  ┌─────────────────────────────────────┐            │
│  │         选择要编辑的字段                │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         点击编辑按钮                    │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         修改字段信息                  │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         保存修改                      │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         刷新字段列表                  │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         实时预览更新                  │            │
│  └─────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

#### 9.2.3 字段删除流程

```
┌─────────────────────────────────────────────────────┐
│                 字段删除流程                          │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│           进入系统设置页面                            │
│  ┌──────────────┐  ┌──────────────┐                │
│  │ 点击模板管理  │  │ 选择目标模板  │                │
│  └──────┬───────┘  └──────┬───────┘                │
│         │                 │                         │
│         └────────┬────────┘                         │
│                  │                                  │
│                  ▼                                  │
│  ┌─────────────────────────────────────┐            │
│  │         选择要删除的字段                │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         点击删除按钮                    │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         确认删除操作                  │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         执行删除操作                  │            │
│  │  • 从数据库删除                      │            │
│  │  • 从本地存储删除（备用）            │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         刷新字段列表                  │            │
│  └──────────────┬───────────────────────┘            │
│                 │                                    │
│                 ▼                                    │
│  ┌─────────────────────────────────────┐            │
│  │         实时预览更新                  │            │
│  └─────────────────────────────────────┘            │
└─────────────────────────────────────────────────────┘
```

### 9.3 字段类型与配置

#### 9.3.1 支持的字段类型

| 字段类型 | 描述 | 适用场景 |
|---------|------|----------|
| 文本输入 | 单行文本输入 | 姓名、电话、邮箱等 |
| 多行文本 | 多行文本输入 | 自我介绍、工作经历等 |
| 数字 | 数字输入 | 年龄、薪资期望等 |
| 下拉选择 | 下拉菜单选择 | 学历、工作经验、招聘渠道等 |
| 单选按钮 | 单选选项 | 性别、是否有相关经验等 |
| 复选框 | 多选选项 | 技能、证书等 |
| 日期 | 日期选择 | 出生日期、入职时间等 |

#### 9.3.2 字段配置项

| 配置项 | 描述 | 适用字段类型 |
|--------|------|--------------|
| 字段名称 | 字段的唯一标识符 | 所有类型 |
| 字段标签 | 字段的显示名称 | 所有类型 |
| 字段类型 | 字段的输入类型 | 所有类型 |
| 必填设置 | 是否为必填字段 | 所有类型 |
| 默认值 | 字段的默认值 | 所有类型 |
| 验证规则 | 字段的验证规则 | 文本、数字、日期等 |
| 选项 | 字段的可选项 | 下拉选择、单选按钮、复选框 |

### 9.4 字段管理操作说明

#### 9.4.1 添加字段
1. 登录系统设置页面
2. 点击"模板管理"标签页
3. 选择要添加字段的模板
4. 点击"+ 添加字段"按钮
5. 填写字段信息：
   - 字段名称：如"name"、"phone"等
   - 字段标签：如"姓名"、"联系电话"等
   - 字段类型：选择合适的字段类型
   - 必填设置：勾选是否为必填字段
   - 默认值：设置字段的默认值（可选）
   - 验证规则：选择合适的验证规则（可选）
   - 选项：填写字段的可选项（适用于选择类型字段）
6. 点击"保存"按钮
7. 字段将被添加到模板中，并在实时预览中显示

#### 9.4.2 编辑字段
1. 登录系统设置页面
2. 点击"模板管理"标签页
3. 选择包含要编辑字段的模板
4. 在字段列表中找到要编辑的字段
5. 点击"编辑"按钮
6. 修改字段信息
7. 点击"保存"按钮
8. 字段修改将被保存，并在实时预览中更新

#### 9.4.3 删除字段
1. 登录系统设置页面
2. 点击"模板管理"标签页
3. 选择包含要删除字段的模板
4. 在字段列表中找到要删除的字段
5. 点击"删除"按钮
6. 确认删除操作
7. 字段将被从模板中删除，并在实时预览中更新

#### 9.4.4 查询字段
1. 登录系统设置页面
2. 点击"模板管理"标签页
3. 选择要查看字段的模板
4. 字段列表将显示该模板的所有字段
5. 可以通过滚动查看所有字段信息

### 9.5 字段数据存储

#### 9.5.1 数据库存储
- **field_configs表**：存储字段配置信息
- **template_field_mappings表**：存储模板与字段的关联关系
- **field_options表**：存储字段的选项信息

#### 9.5.2 本地存储（备用）
- 当数据库连接失败时，字段配置会保存到localStorage中
- 本地存储的键格式：`templateFields_${templateId}`
- 当数据库连接恢复时，本地存储的配置会同步到数据库

### 9.6 字段管理最佳实践

1. **命名规范**：字段名称使用小写字母和下划线，如"phone"、"work_experience"
2. **必填设置**：核心信息字段（如姓名、电话）应设置为必填
3. **验证规则**：根据字段类型设置合适的验证规则，如手机号验证
4. **选项管理**：下拉选择、单选按钮、复选框类型的字段应提供合理的选项
5. **默认值**：为常用字段设置合理的默认值，提高用户填写效率
6. **字段排序**：根据字段的重要性和填写顺序合理排序
7. **性能考虑**：避免添加过多字段，影响表单加载和提交性能
8. **兼容性**：确保字段类型在不同浏览器和设备上都能正常显示和使用

### 9.7 字段管理权限控制

| 角色 | 权限 |
|------|------|
| 管理员 | 可添加、编辑、删除、查询所有字段 |
| HR专员 | 可查询字段，不可修改字段配置 |
| 普通用户 | 无字段管理权限 |

### C. 版本历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0 | 2026-03-28 | 初始版本 | 系统分析团队 |

---

**文档结束**

*本文档详细描述了义齿工厂招聘系统的完整业务流程，包括前端交互逻辑、后端处理流程、数据流转机制、业务规则校验、异常处理策略和用户体验优化措施。开发团队应严格按照本文档规范进行系统开发和维护。*
