/**
 * 全局错误处理模块
 * 用于捕获和记录 Supabase 错误
 */

class ErrorHandler {
    constructor() {
        this.errors = [];
        this.init();
    }

    init() {
        // 捕获全局错误
        window.addEventListener('error', (event) => {
            this.handleError(event.error, 'Global Error');
        });

        // 捕获未处理的 Promise 错误
        window.addEventListener('unhandledrejection', (event) => {
            this.handleError(event.reason, 'Unhandled Promise Rejection');
        });

        // 拦截 console.error
        const originalConsoleError = console.error;
        console.error = (...args) => {
            // 检查是否是 Supabase 错误
            const errorString = args.join(' ');
            if (errorString.includes('400') || errorString.includes('Bad Request')) {
                this.handleError({
                    message: errorString,
                    args: args
                }, 'Supabase 400 Error');
            }
            originalConsoleError.apply(console, args);
        };
    }

    handleError(error, context) {
        const errorInfo = {
            timestamp: new Date().toISOString(),
            context: context,
            message: error?.message || error,
            stack: error?.stack,
            error: error
        };

        this.errors.push(errorInfo);
        
        // 显示错误提示
        this.showErrorNotification(errorInfo);
        
        // 发送到控制台
        console.error('[ErrorHandler]', context, error);
    }

    showErrorNotification(errorInfo) {
        // 创建错误提示元素
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #ff4d4f;
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 9999;
            max-width: 400px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            font-size: 14px;
            line-height: 1.5;
        `;
        
        notification.innerHTML = `
            <div style="font-weight: bold; margin-bottom: 8px;">⚠️ 错误捕获</div>
            <div style="margin-bottom: 8px;">${errorInfo.context}</div>
            <div style="font-size: 12px; opacity: 0.9;">${errorInfo.message}</div>
            <button onclick="this.parentElement.remove()" style="
                margin-top: 10px;
                padding: 5px 15px;
                background: white;
                color: #ff4d4f;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
            ">关闭</button>
        `;
        
        document.body.appendChild(notification);
        
        // 5秒后自动移除
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }

    getErrors() {
        return this.errors;
    }

    clearErrors() {
        this.errors = [];
    }
}

// 创建全局实例
window.errorHandler = new ErrorHandler();
