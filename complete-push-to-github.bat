@echo off
chcp 65001 >nul
echo ==========================================
echo   完整推送所有文件到 GitHub
echo ==========================================
echo.

set SOURCE_DIR=D:\义齿工厂招聘小助手
set TARGET_DIR=D:\GitHub\dental_recruitment_systemV2.0

echo [1/4] 复制所有缺失的 HTML 文件...

copy /Y "%SOURCE_DIR%\booking.html" "%TARGET_DIR%\" 2>nul && echo   ✓ booking.html
copy /Y "%SOURCE_DIR%\index.html" "%TARGET_DIR%\" 2>nul && echo   ✓ index.html
copy /Y "%SOURCE_DIR%\status-query.html" "%TARGET_DIR%\" 2>nul && echo   ✓ status-query.html
copy /Y "%SOURCE_DIR%\application-form.html" "%TARGET_DIR%\" 2>nul && echo   ✓ application-form.html
copy /Y "%SOURCE_DIR%\applications.html" "%TARGET_DIR%\" 2>nul && echo   ✓ applications.html
copy /Y "%SOURCE_DIR%\admin-standalone.html" "%TARGET_DIR%\" 2>nul && echo   ✓ admin-standalone.html
copy /Y "%SOURCE_DIR%\permissions.html" "%TARGET_DIR%\" 2>nul && echo   ✓ permissions.html
copy /Y "%SOURCE_DIR%\settings.html" "%TARGET_DIR%\" 2>nul && echo   ✓ settings.html
copy /Y "%SOURCE_DIR%\success-standalone.html" "%TARGET_DIR%\" 2>nul && echo   ✓ success-standalone.html
copy /Y "%SOURCE_DIR%\test-data-sync.html" "%TARGET_DIR%\" 2>nul && echo   ✓ test-data-sync.html
copy /Y "%SOURCE_DIR%\login-new.html" "%TARGET_DIR%\" 2>nul && echo   ✓ login-new.html
copy /Y "%SOURCE_DIR%\integrated-applications.html" "%TARGET_DIR%\" 2>nul && echo   ✓ integrated-applications.html
copy /Y "%SOURCE_DIR%\recruitment-dashboard.html" "%TARGET_DIR%\" 2>nul && echo   ✓ recruitment-dashboard.html
copy /Y "%SOURCE_DIR%\recruitment-process.html" "%TARGET_DIR%\" 2>nul && echo   ✓ recruitment-process.html
copy /Y "%SOURCE_DIR%\candidate-form-complete.html" "%TARGET_DIR%\" 2>nul && echo   ✓ candidate-form-complete.html

echo.
echo [2/4] 检查文件...
dir /B "%TARGET_DIR%\*.html" | find /c ".html"

echo.
echo [3/4] 提交到 Git...
cd /d "%TARGET_DIR%"
git add .
git commit -m "Add missing HTML files: booking.html, index.html, status-query.html, etc."

echo.
echo [4/4] 推送到 GitHub...
git push -f origin main

echo.
echo ==========================================
if %errorlevel% equ 0 (
    echo ✅ 推送成功！
    echo.
    echo 请等待 2-3 分钟让 GitHub Pages 重新部署。
) else (
    echo ❌ 推送失败
)
echo ==========================================
pause
