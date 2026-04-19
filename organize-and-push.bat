@echo off
chcp 65001 >nul
echo ==========================================
echo   完整文件组织与推送工具
echo ==========================================
echo.

set SOURCE_DIR=D:\义齿工厂招聘小助手
set TARGET_DIR=D:\GitHub\dental_recruitment_systemV2.0

echo Step 1: 清理旧的 GitHub 目录...
if exist "%TARGET_DIR%" (
    rmdir /S /Q "%TARGET_DIR%"
    echo   已删除旧目录
)
mkdir "%TARGET_DIR%"
echo   已创建新目录

echo.
echo Step 2: 创建目录结构...
mkdir "%TARGET_DIR%\css"
mkdir "%TARGET_DIR%\js"
mkdir "%TARGET_DIR%\js\config"
mkdir "%TARGET_DIR%\js\components"
mkdir "%TARGET_DIR%\js\utils"
echo   目录结构创建完成

echo.
echo Step 3: 复制 CSS 文件...
copy /Y "%SOURCE_DIR%\css\*.css" "%TARGET_DIR%\css\"
echo   CSS 文件复制完成

echo.
echo Step 4: 复制 JS 文件...
copy /Y "%SOURCE_DIR%\js\config.js" "%TARGET_DIR%\js\"
copy /Y "%SOURCE_DIR%\js\config\*.js" "%TARGET_DIR%\js\config\"
copy /Y "%SOURCE_DIR%\js\components\*.js" "%TARGET_DIR%\js\components\"
copy /Y "%SOURCE_DIR%\js\utils\*.js" "%TARGET_DIR%\js\utils\"
copy /Y "%SOURCE_DIR%\js\recruitment-process.js" "%TARGET_DIR%\js\"
copy /Y "%SOURCE_DIR%\js\recruitment-dashboard.js" "%TARGET_DIR%\js\"
copy /Y "%SOURCE_DIR%\js\recruitment-dashboard-new.js" "%TARGET_DIR%\js\"
echo   JS 文件复制完成

echo.
echo Step 5: 复制所有 HTML 文件...
copy /Y "%SOURCE_DIR%\*.html" "%TARGET_DIR%\"
echo   HTML 文件复制完成

echo.
echo Step 6: 验证目录结构...
echo   CSS 目录内容:
dir /B "%TARGET_DIR%\css\" 2>nul || echo     (空)
echo.
echo   JS 目录内容:
dir /B "%TARGET_DIR%\js\" 2>nul || echo     (空)
echo.
echo   JS\config 目录内容:
dir /B "%TARGET_DIR%\js\config\" 2>nul || echo     (空)
echo.
echo   JS\components 目录内容:
dir /B "%TARGET_DIR%\js\components\" 2>nul || echo     (空)
echo.
echo   JS\utils 目录内容:
dir /B "%TARGET_DIR%\js\utils\" 2>nul || echo     (空)

echo.
echo ==========================================
echo 文件组织完成！
echo ==========================================
echo.
echo 现在推送到 GitHub...
echo.

cd /d "%TARGET_DIR%"

echo Step 7: 初始化 Git 仓库...
git init

echo.
echo Step 8: 添加所有文件...
git add .

echo.
echo Step 9: 提交文件...
git commit -m "Organize file directory structure - fix 404 errors"

echo.
echo Step 10: 设置分支名...
git branch -M main

echo.
echo Step 11: 添加远程仓库...
git remote remove origin 2>nul
git remote add origin https://github.com/As-2026learning/dental_recruitment_systemV2.0.git

echo.
echo Step 12: 推送到 GitHub...
git push -f origin main

echo.
echo ==========================================
echo 完成！
echo ==========================================
echo.
echo 请等待 1-2 分钟让 GitHub Pages 重新部署。
echo 然后访问: https://as-2026learning.github.io/dental_recruitment_systemV2.0/
echo.
pause
