# 义齿工厂招聘管理系统

一个功能完善的招聘管理系统，包含应聘信息收集、面试预约、后台管理等功能。

## 🌐 在线访问

**GitHub Pages 地址**: `https://[您的用户名].github.io/[仓库名]/`

## 📋 功能特性

### 前端页面
- **应聘表单页面** (`candidate-form-complete.html`) - 应聘者填写信息
- **面试预约页面** (`booking.html`) - 预约面试时间
- **预约成功页面** (`success-standalone.html`) - 预约成功提示

### 后台管理页面
- **登录页面** (`login.html`) - 账号登录
- **应聘信息综合管理** (`integrated-applications.html`) - 查看、管理应聘信息
- **预约管理** (`admin-standalone.html`) - 管理面试预约
- **系统设置** (`settings.html`) - 配置岗位、时段、模板等
- **权限管理** (`permissions.html`) - 管理用户账号和权限

### 权限系统
- **管理员** (admin): 拥有所有权限
- **操作员** (operator): 日常操作权限
- **查看员** (viewer): 仅查看权限

## 🔑 默认账号

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 管理员 | admin | admin123 |
| 操作员 | operator | operator123 |

## 🚀 部署到 GitHub Pages

### 步骤 1: 创建 GitHub 仓库

1. 登录 [GitHub](https://github.com)
2. 点击右上角 "+" → "New repository"
3. 输入仓库名（如 `dental-factory-recruitment`）
4. 选择 "Public"（公开）
5. 点击 "Create repository"

### 步骤 2: 上传代码

#### 方法一：通过 Git 命令行

```bash
# 在项目目录中初始化 Git
git init

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit"

# 添加远程仓库（替换为您的仓库地址）
git remote add origin https://github.com/[您的用户名]/[仓库名].git

# 推送代码
git push -u origin main
```

#### 方法二：通过 GitHub 网页上传

1. 在仓库页面点击 "Add file" → "Upload files"
2. 拖拽或选择项目文件上传
3. 点击 "Commit changes"

### 步骤 3: 启用 GitHub Pages

1. 进入仓库的 "Settings"（设置）
2. 左侧菜单选择 "Pages"
3. "Source" 部分选择 "Deploy from a branch"
4. "Branch" 选择 "main" 分支，文件夹选择 "/ (root)"
5. 点击 "Save"
6. 等待几分钟，页面会显示访问链接

## 📁 项目结构

```
.
├── login.html                  # 登录页面
├── candidate-form-complete.html # 应聘表单
├── booking.html                # 面试预约
├── success-standalone.html     # 预约成功页
├── integrated-applications.html # 应聘信息管理
├── admin-standalone.html       # 预约管理
├── settings.html               # 系统设置
├── permissions.html            # 权限管理
├── auth.js                     # 权限管理模块
├── css/                        # 样式文件
├── js/                         # JavaScript 文件
└── README.md                   # 项目说明
```

## ⚠️ 注意事项

1. **数据存储**: 本项目使用 localStorage 存储数据，数据保存在用户浏览器中
2. **多设备同步**: 如需多设备数据同步，需要部署后端服务
3. **安全性**: 当前为演示版本，密码明文存储，生产环境请使用加密

## 🔧 技术栈

- **前端**: HTML5, CSS3, JavaScript (原生)
- **数据库**: Supabase (PostgreSQL)
- **部署**: GitHub Pages

## 📞 联系方式

如有问题或建议，欢迎联系！

---

**注意**: 本项目为演示用途，请勿用于生产环境。
