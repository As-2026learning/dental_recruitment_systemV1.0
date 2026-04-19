/**
 * 全局配置模块 - Global Config Module
 * 统一管理系统配置，替代硬编码的敏感信息
 * 
 * fix: 集中管理Supabase配置 - 解决硬编码API Key的安全问题
 * 创建日期: 2026-04-19
 */

(function(global) {
    'use strict';

    /**
     * 配置对象
     * 注意：浏览器环境无法直接读取.env文件，
     * 生产环境应使用构建工具注入或使用后端代理
     */
    const CONFIG = {
        // Supabase 配置
        // 这些值应该从环境变量读取，这里提供默认值
        SUPABASE_URL: 'https://dxrghlqnwfwpuxjvyisv.supabase.co',
        // fix: 2026-04-19 更新 API Key - 旧 Key 已泄露，更换为新 Key
        SUPABASE_KEY: 'sb_publishable_jIeq2dPdvQbWo0yyHGhfyw_QL5C5R_Y',
        
        // 应用信息
        APP_NAME: '义齿工厂招聘系统',
        APP_VERSION: '1.0.0',
        
        // 调试模式
        DEBUG: false,
        
        // 日志级别: 'debug', 'info', 'warn', 'error'
        LOG_LEVEL: 'info',
        
        /**
         * 获取配置值
         * @param {string} key - 配置键名
         * @param {*} defaultValue - 默认值
         * @returns {*} 配置值
         */
        get: function(key, defaultValue) {
            if (this.hasOwnProperty(key)) {
                return this[key];
            }
            return defaultValue;
        },
        
        /**
         * 检查是否为调试模式
         * @returns {boolean}
         */
        isDebug: function() {
            return this.DEBUG === true;
        },
        
        /**
         * 打印调试信息
         * @param {...*} args - 要打印的内容
         */
        log: function(...args) {
            if (this.isDebug()) {
                console.log('[CONFIG]', ...args);
            }
        }
    };

    // 暴露到全局作用域
    global.CONFIG = CONFIG;
    
    // 同时提供 ES6 模块导出（如果支持）
    if (typeof module !== 'undefined' && module.exports) {
        module.exports = CONFIG;
    }
    
    // 初始化日志
    if (CONFIG.isDebug()) {
        console.log('[CONFIG] 配置模块已加载，版本:', CONFIG.APP_VERSION);
    }

})(window);
