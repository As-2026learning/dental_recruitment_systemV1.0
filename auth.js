/**
 * 权限管理模块 - Auth Module
 * 提供登录认证、权限检查、用户管理等功能
 */

(function(global) {
    'use strict';

    // 权限配置
    const PERMISSION_CONFIG = {
        admin: {
            name: '管理员',
            description: '拥有系统所有功能的完整权限',
            permissions: {
                applications: ['view', 'add', 'edit', 'delete', 'export', 'status'],
                bookings: ['view', 'add', 'edit', 'delete', 'confirm', 'export'],
                settings: ['view', 'edit', 'templates', 'positions', 'timeslots', 'banners'],
                permissions: ['view', 'edit', 'users', 'roles'],
                system: ['view', 'backup', 'restore', 'logs']
            }
        },
        operator: {
            name: '操作员',
            description: '拥有日常操作权限',
            permissions: {
                applications: ['view', 'add', 'edit', 'export', 'status'],
                bookings: ['view', 'add', 'edit', 'confirm', 'export'],
                settings: ['view'],
                permissions: [],
                system: []
            }
        },
        viewer: {
            name: '查看员',
            description: '仅拥有查看权限',
            permissions: {
                applications: ['view', 'export'],
                bookings: ['view', 'export'],
                settings: [],
                permissions: [],
                system: []
            }
        }
    };

    // 页面权限映射
    const PAGE_PERMISSIONS = {
        'integrated-applications.html': { module: 'applications', action: 'view' },
        'admin-standalone.html': { module: 'bookings', action: 'view' },
        'settings.html': { module: 'settings', action: 'view' },
        'permissions.html': { module: 'permissions', action: 'view' }
    };

    /**
     * Auth 对象
     */
    const Auth = {
        /**
         * 初始化认证系统
         */
        init: function() {
            this.checkLoginStatus();
        },

        /**
         * 检查登录状态
         */
        checkLoginStatus: function() {
            const isLoggedIn = localStorage.getItem('adminLoggedIn') === 'true';
            const token = localStorage.getItem('adminToken');
            const currentUser = this.getCurrentUser();

            if (!isLoggedIn || !token || !currentUser) {
                this.redirectToLogin();
                return false;
            }

            // 检查页面权限
            return this.checkPagePermission();
        },

        /**
         * 获取当前登录用户
         */
        getCurrentUser: function() {
            const userStr = localStorage.getItem('currentUser');
            return userStr ? JSON.parse(userStr) : null;
        },

        /**
         * 获取用户角色
         */
        getUserRole: function() {
            const user = this.getCurrentUser();
            return user ? user.role : null;
        },

        /**
         * 检查当前页面权限
         */
        checkPagePermission: function() {
            const currentPage = window.location.pathname.split('/').pop();
            const pagePerm = PAGE_PERMISSIONS[currentPage];

            if (!pagePerm) {
                return true; // 未配置的页面默认允许访问
            }

            const hasPermission = this.hasPermission(pagePerm.module, pagePerm.action);

            if (!hasPermission) {
                this.showNoPermission();
                return false;
            }

            return true;
        },

        /**
         * 检查具体权限
         * @param {string} module - 模块名
         * @param {string} action - 操作名
         */
        hasPermission: function(module, action) {
            const user = this.getCurrentUser();
            if (!user) return false;

            const role = user.role;
            const roleConfig = PERMISSION_CONFIG[role];

            if (!roleConfig) return false;

            // 管理员拥有所有权限
            if (role === 'admin') return true;

            const modulePerms = roleConfig.permissions[module];
            if (!modulePerms) return false;

            return modulePerms.includes(action);
        },

        /**
         * 检查是否有某个模块的任何权限
         * @param {string} module - 模块名
         */
        hasModuleAccess: function(module) {
            const user = this.getCurrentUser();
            if (!user) return false;

            const role = user.role;
            const roleConfig = PERMISSION_CONFIG[role];

            if (!roleConfig) return false;

            // 管理员拥有所有权限
            if (role === 'admin') return true;

            const modulePerms = roleConfig.permissions[module];
            return modulePerms && modulePerms.length > 0;
        },

        /**
         * 显示无权限提示
         */
        showNoPermission: function() {
            alert('您没有权限访问此页面');
            // 跳转到有权限的页面
            this.redirectToAccessiblePage();
        },

        /**
         * 重定向到登录页面
         */
        redirectToLogin: function() {
            // 清除登录状态
            this.logout();
            // 跳转到登录页
            window.location.href = 'login.html';
        },

        /**
         * 重定向到用户有权限访问的页面
         */
        redirectToAccessiblePage: function() {
            const user = this.getCurrentUser();
            if (!user) {
                this.redirectToLogin();
                return;
            }

            // 按优先级检查可访问页面
            const pages = [
                { url: 'integrated-applications.html', module: 'applications' },
                { url: 'admin-standalone.html', module: 'bookings' },
                { url: 'settings.html', module: 'settings' }
            ];

            for (const page of pages) {
                if (this.hasModuleAccess(page.module)) {
                    window.location.href = page.url;
                    return;
                }
            }

            // 如果没有可访问页面，退出登录
            this.redirectToLogin();
        },

        /**
         * 退出登录
         */
        logout: function() {
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminLoggedIn');
            localStorage.removeItem('currentUser');
        },

        /**
         * 获取权限配置
         */
        getPermissionConfig: function() {
            return PERMISSION_CONFIG;
        },

        /**
         * 获取当前用户的权限列表
         */
        getUserPermissions: function() {
            const user = this.getCurrentUser();
            if (!user) return {};

            const roleConfig = PERMISSION_CONFIG[user.role];
            return roleConfig ? roleConfig.permissions : {};
        },

        /**
         * 根据权限显示/隐藏元素
         * @param {string} module - 模块名
         * @param {string} action - 操作名
         * @param {string|Element} element - 元素或选择器
         */
        toggleElement: function(module, action, element) {
            const hasPerm = this.hasPermission(module, action);
            const el = typeof element === 'string' ? document.querySelector(element) : element;

            if (el) {
                el.style.display = hasPerm ? '' : 'none';
            }

            return hasPerm;
        },

        /**
         * 禁用无权限的按钮
         * @param {string} module - 模块名
         * @param {string} action - 操作名
         * @param {string|Element} element - 元素或选择器
         */
        disableElement: function(module, action, element) {
            const hasPerm = this.hasPermission(module, action);
            const el = typeof element === 'string' ? document.querySelector(element) : element;

            if (el && !hasPerm) {
                el.disabled = true;
                el.style.opacity = '0.5';
                el.style.cursor = 'not-allowed';
                el.title = '您没有此操作的权限';
            }

            return hasPerm;
        }
    };

    // 暴露到全局
    global.Auth = Auth;

    // 自动初始化（如果页面加载完成）
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            Auth.init();
        });
    } else {
        // DOM 已加载
        Auth.init();
    }

})(window);
