@echo off
chcp 65001 >nul
echo ==========================================
echo   修复 GitHub Pages 部署问题
echo ==========================================
echo.

set SOURCE_DIR=D:\义齿工厂招聘小助手
set TARGET_DIR=D:\GitHub\dental_recruitment_systemV2.0

echo [1/5] 清理旧的 GitHub 目录...
if exist "%TARGET_DIR%" (
    rmdir /S /Q "%TARGET_DIR%"
    echo     已删除旧目录
)
mkdir "%TARGET_DIR%"
echo     已创建新目录: %TARGET_DIR%

echo.
echo [2/5] 创建目录结构...
mkdir "%TARGET_DIR%\css"
mkdir "%TARGET_DIR%\js"
mkdir "%TARGET_DIR%\js\config"
mkdir "%TARGET_DIR%\js\components"
mkdir "%TARGET_DIR%\js\utils"
echo     目录结构创建完成

echo.
echo [3/5] 复制 CSS 文件...
copy /Y "%SOURCE_DIR%\css\*.css" "%TARGET_DIR%\css\" >nul
echo     已复制 CSS 文件:
for %%f in (%TARGET_DIR%\css\*.css) do echo       - %%~nxf

echo.
echo [4/5] 复制 JS 文件...
:: 复制主目录 JS
copy /Y "%SOURCE_DIR%\js\config.js" "%TARGET_DIR%\js\" >nul
copy /Y "%SOURCE_DIR%\js\recruitment-process.js" "%TARGET_DIR%\js\" >nul
copy /Y "%SOURCE_DIR%\js\recruitment-dashboard.js" "%TARGET_DIR%\js\" >nul
copy /Y "%SOURCE_DIR%\js\recruitment-dashboard-new.js" "%TARGET_DIR%\js\" >nul

:: 复制子目录 JS
copy /Y "%SOURCE_DIR%\js\config\*.js" "%TARGET_DIR%\js\config\" >nul
copy /Y "%SOURCE_DIR%\js\components\*.js" "%TARGET_DIR%\js\components\" >nul
copy /Y "%SOURCE_DIR%\js\utils\*.js" "%TARGET_DIR%\js\utils\" >nul

echo     已复制 JS 文件:
echo       js\config.js
echo       js\recruitment-process.js
echo       js\recruitment-dashboard.js
echo       js\recruitment-dashboard-new.js
for %%f in (%TARGET_DIR%\js\config\*.js) do echo       js\config\%%~nxf
for %%f in (%TARGET_DIR%\js\components\*.js) do echo       js\components\%%~nxf
for %%f in (%TARGET_DIR%\js\utils\*.js) do echo       js\utils\%%~nxf

echo.
echo [5/5] 复制所有 HTML 文件...
copy /Y "%SOURCE_DIR%\*.html" "%TARGET_DIR%\" >nul
echo     已复制 HTML 文件:
for %%f in (%TARGET_DIR%\*.html) do echo       - %%~nxf

echo.
echo ==========================================
echo 文件组织完成！
echo ==========================================
echo.
echo 目录结构验证:
echo   css\ 目录文件数:
set /a count=0
for %%f in (%TARGET_DIR%\css\*.css) do set /a count+=1
echo     %count% 个文件

echo   js\ 目录文件数:
set /a count=0
for %%f in (%TARGET_DIR%\js\*.js) do set /a count+=1
for %%f in (%TARGET_DIR%\js\config\*.js) do set /a count+=1
for %%f in (%TARGET_DIR%\js\components\*.js) do set /a count+=1
for %%f in (%TARGET_DIR%\js\utils\*.js) do set /a count+=1
echo     %count% 个文件

echo   HTML 文件数:
set /a count=0
for %%f in (%TARGET_DIR%\*.html) do set /a count+=1
echo     %count% 个文件

echo.
echo ==========================================
echo 现在推送到 GitHub...
echo ==========================================
echo.

cd /d "%TARGET_DIR%"

echo [6/8] 初始化 Git 仓库...
git init

echo.
echo [7/8] 添加并提交文件...
git add .
git commit -m "Fix: Organize files into correct directory structure (css/, js/, etc.)"

echo.
echo [8/8] 推送到 GitHub...
git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/As-2026learning/dental_recruitment_systemV2.0.git
git push -f origin main

echo.
echo ==========================================
echo 完成！
echo ==========================================
echo.
if %errorlevel% equ 0 (
    echo ✅ 推送成功！
    echo.
    echo 请等待 2-3 分钟让 GitHub Pages 重新部署。
    echo 然后访问:
    echo   https://as-2026learning.github.io/dental_recruitment_systemV2.0/recruitment-process.html
    echo   https://as-2026learning.github.io/dental_recruitment_systemV2.0/recruitment-dashboard.html
) else (
    echo ❌ 推送失败，请检查网络连接或手动推送
    echo.
    echo 手动推送步骤:
    echo   cd D:\GitHub\dental_recruitment_systemV2.0
    echo   git push -f origin main
)
echo.
pause
