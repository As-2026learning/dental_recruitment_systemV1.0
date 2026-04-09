@echo off
chcp 65001 >nul
echo ==========================================
echo   义齿工厂招聘系统 - 本地服务器启动工具
echo ==========================================
echo.

:: 检查是否安装了 Python
python --version >nul 2>&1
if %errorlevel% == 0 (
    echo [✓] 检测到 Python，使用 Python HTTP 服务器
    echo.
    echo 正在启动服务器...
    echo 请访问: http://localhost:8080
    echo.
    python -m http.server 8080
    goto :end
)

:: 检查是否安装了 Node.js
node --version >nul 2>&1
if %errorlevel% == 0 (
    echo [✓] 检测到 Node.js，使用 npx serve
    echo.
    echo 正在启动服务器...
    echo 请访问: http://localhost:8080
    echo.
    npx serve -l 8080
    goto :end
)

:: 检查是否安装了 PHP
php --version >nul 2>&1
if %errorlevel% == 0 (
    echo [✓] 检测到 PHP，使用 PHP 内置服务器
    echo.
    echo 正在启动服务器...
    echo 请访问: http://localhost:8080
    echo.
    php -S localhost:8080
    goto :end
)

echo [✗] 未检测到可用的服务器工具
echo.
echo 请安装以下任一工具：
echo   1. Python (推荐): https://www.python.org/downloads/
echo   2. Node.js: https://nodejs.org/
echo   3. PHP: https://www.php.net/downloads.php
echo.
echo 安装后重新运行此脚本。
echo.
pause

:end
