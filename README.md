# 面试预约系统

一个基于Supabase和前端技术栈的零成本面试预约管理系统。

## 🌐 在线访问

**系统入口**: [https://as-2026learning.github.io/dental-factory-recruitment/index.html](https://as-2026learning.github.io/dental-factory-recruitment/index.html)

### 直接访问链接
- [📋 填写应聘信息](https://as-2026learning.github.io/dental-factory-recruitment/candidate-form-complete.html)
- [📅 预约面试](https://as-2026learning.github.io/dental-factory-recruitment/booking.html)
- [🔐 后台管理登录](https://as-2026learning.github.io/dental-factory-recruitment/login.html)

**默认账号**: admin / admin123

## 功能特点

- 📅 面试预约：求职者可在线选择日期和时段进行预约
- 📊 预约管理：管理员可查看、确认、取消预约记录
- ⚙️ 系统配置：支持岗位管理、时段配置、温馨提示和横幅文本设置
- 📤 数据导出：可导出预约数据为Excel格式
- 📱 响应式设计：支持PC、平板和移动设备
- 🔒 安全可靠：基于Supabase的安全机制

## 技术栈

- **前端**：HTML5, CSS3, JavaScript (ES6+)
- **后端**：Supabase (BaaS)
- **数据库**：PostgreSQL
- **部署**：GitHub Pages

## 快速开始

### 1. 环境准备

1. 注册 [Supabase](https://supabase.com) 账号
2. 创建新项目
3. 获取项目的 `Project URL` 和 `Anon Public Key`

### 2. 数据库初始化

1. 在Supabase控制台中打开SQL Editor
2. 执行 `sql/create-config-tables.sql` 脚本创建所需的数据库表

### 3. 配置连接信息

编辑 `js/config.js` 文件，填入你的Supabase项目信息：

```javascript
const SUPABASE_URL = '你的Project URL';
const SUPABASE_ANON_KEY = '你的Anon Public Key';
```

### 4. 本地测试

启动本地服务器：

```bash
python -m http.server 8000
```

然后访问：
- 预约页面：http://localhost:8000/booking.html
- 管理页面：http://localhost:8000/admin-standalone.html
- 设置页面：http://localhost:8000/settings.html
- 数据库检查：http://localhost:8000/db-check.html

### 5. 部署到GitHub Pages

1. 创建GitHub仓库
2. 上传所有文件到仓库
3. 在仓库设置中启用GitHub Pages
4. 选择 `main` 分支作为源
5. 等待部署完成后，访问生成的URL

## 系统功能

### 预约流程
1. 求职者访问预约页面
2. 填写个人信息（姓名、电话、应聘岗位）
3. 选择面试日期和时段
4. 提交预约
5. 系统生成预约记录并跳转到成功页面

### 管理功能
1. 查看所有预约记录
2. 确认或取消预约
3. 按日期、状态、时段筛选预约
4. 导出预约数据为Excel
5. 配置系统参数

### 设置功能
1. 管理招聘岗位
2. 配置面试时段和容量
3. 设置预约须知和温馨提示
4. 自定义横幅文本

## 数据库结构

### 主要表结构

- **positions**：岗位表
- **time_slots**：时段表
- **system_config**：系统配置表
- **bookings**：预约表
- **applications**：应聘信息表
- **template_configs**：模板配置表

详细结构请参考以下文件：
- `sql/create-config-tables.sql`：创建基础配置表
- `sql/create-application-table.sql`：创建应聘信息表
- `sql/create-template-config-table.sql`：创建模板配置表

## 安全注意事项

- 本系统使用Supabase的匿名访问策略，适合内部使用
- 如需对外公开使用，建议开启Supabase的认证功能
- 定期备份数据库数据

## 维护与更新

- 定期检查Supabase的API使用情况
- 及时更新依赖库
- 根据实际需求调整系统配置

## 许可证

MIT

## 联系信息

如有问题或建议，请联系系统管理员。