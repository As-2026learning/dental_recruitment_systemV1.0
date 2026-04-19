# Supabase Auth 认证系统实施指南

## 概述
本文档指导如何将系统从本地模拟登录迁移到 Supabase Auth 认证系统。

## 实施步骤

### 第一步：执行数据库初始化脚本

1. 登录 Supabase 控制台
2. 进入 SQL Editor
3. 新建查询，执行 `setup-supabase-auth.sql` 中的全部内容

### 第二步：创建管理员用户

#### 方法 A：通过 Supabase 控制台（推荐）

1. 进入 Authentication → Users
2. 点击 "New User"
3. 输入邮箱和密码（密码至少6位）
4. 记录创建后的用户 UUID

#### 方法 B：通过 API（需要 Service Role Key）

```javascript
// 使用 Supabase Admin API 创建用户
const { data, error } = await supabase.auth.admin.createUser({
  email: 'admin@example.com',
  password: 'your-password',
  email_confirm: true
});
```

### 第三步：设置用户角色

创建用户后，执行 SQL 设置角色：

```sql
-- 将 'user-uuid-here' 替换为实际的用户 UUID
INSERT INTO public.user_roles (user_id, role, name)
VALUES ('user-uuid-here', 'admin', '系统管理员');
```

### 第四步：测试登录

1. 打开 `login-new.html`
2. 使用创建的邮箱和密码登录
3. 验证是否能正常跳转到后台页面

### 第五步：更新其他后台页面

需要将所有后台页面的登录检查更新为支持 Supabase Auth：

- `recruitment-process.html`
- `recruitment-dashboard.html`
- `admin-standalone.html`
- `settings.html`
- `permissions.html`

更新内容：
1. 将登录检查跳转从 `login.html` 改为 `login-new.html`
2. 更新退出登录函数支持 Supabase Auth

### 第六步：切换正式登录页面

测试完成后：
1. 将 `login.html` 重命名为 `login-old.html`
2. 将 `login-new.html` 重命名为 `login.html`

## 安全配置

### RLS 策略说明

执行 `setup-supabase-auth.sql` 后，系统会配置以下安全策略：

| 表 | 认证用户权限 | 匿名用户权限 |
|----|-------------|-------------|
| applications | 全部操作 | 仅插入 |
| bookings | 全部操作 | 仅插入 |
| recruitment_process | 全部操作 | 无 |
| positions | 读取 | 无 |
| job_types | 读取 | 无 |
| system_config | 读取 | 读取 |
| user_roles | 读取 | 无 |

### 角色权限

- **admin**: 系统管理员，拥有所有权限
- **operator**: 操作员，拥有日常操作权限
- **viewer**: 查看员，仅拥有查看权限

## 故障排除

### 问题1：登录后无法读取数据

**原因**: RLS 策略未正确配置

**解决**: 
1. 检查 `setup-supabase-auth.sql` 是否已完整执行
2. 确认用户角色已正确设置

### 问题2：提示 "Email not confirmed"

**原因**: 用户邮箱未验证

**解决**:
1. 在 Supabase 控制台手动确认用户邮箱
2. 或在创建用户时设置 `email_confirm: true`

### 问题3：旧登录方式失效

**原因**: 系统已切换到新认证方式

**解决**: 
1. 使用 `login-new.html` 登录
2. 或按照第六步切换正式登录页面

## 回滚方案

如需回滚到旧系统：

1. 恢复 `login.html`（如果已重命名）
2. 在 Supabase 控制台禁用 RLS：
   ```sql
   ALTER TABLE applications DISABLE ROW LEVEL SECURITY;
   ALTER TABLE bookings DISABLE ROW LEVEL SECURITY;
   ```

## 注意事项

1. **备份数据**: 实施前请备份数据库
2. **测试环境**: 建议先在测试环境验证
3. **用户通知**: 提前通知用户登录方式变更
4. **密码要求**: Supabase 要求密码至少6位字符

## 后续优化建议

1. 实现密码重置功能
2. 添加登录日志记录
3. 实现多因素认证（MFA）
4. 设置会话过期时间
