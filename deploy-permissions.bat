@echo off
chcp 65001 >nul
echo ==========================================
echo   部署权限管理页面到 GitHub Pages
echo ==========================================
echo.

set SOURCE_DIR=D:\义齿工厂招聘小助手
set TARGET_DIR=D:\GitHub\dental_recruitment_systemV2.0

echo [1/3] 复制 permissions.html 文件...

if exist "%SOURCE_DIR%\permissions.html" (
    copy /Y "%SOURCE_DIR%\permissions.html" "%TARGET_DIR%\"
    if %errorlevel% equ 0 (
        echo   ✓ permissions.html 复制成功
    ) else (
        echo   ✗ permissions.html 复制失败
        pause
        exit /b 1
    )
) else (
    echo   ✗ 源文件不存在
    pause
    exit /b 1
)

echo.
echo [2/3] 检查目标目录...
if exist "%TARGET_DIR%\permissions.html" (
    echo   ✓ permissions.html 已存在于目标目录
) else (
    echo   ✗ permissions.html 不存在于目标目录
    pause
    exit /b 1
)

echo.
echo [3/3] 提交并推送...
cd /d "%TARGET_DIR%"
git add permissions.html
git commit -m "Update permissions.html - fix user creation bug"
git push -f origin main

echo.
echo ==========================================
if %errorlevel% equ 0 (
    echo ✅ 部署成功！
    echo.
    echo 请等待 2-3 分钟让 GitHub Pages 重新部署。
) else (
    echo ❌ 部署失败
)
echo ==========================================
pause