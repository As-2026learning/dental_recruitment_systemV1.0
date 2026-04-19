@echo off
chcp 65001 >nul
echo ==========================================
echo   File Organization Tool
echo ==========================================
echo.

set SOURCE_DIR=D:\义齿工厂招聘小助手
set TARGET_DIR=D:\GitHub\dental_recruitment_systemV2.0

echo Creating directories...
if not exist "%TARGET_DIR%\css" mkdir "%TARGET_DIR%\css"
if not exist "%TARGET_DIR%\js" mkdir "%TARGET_DIR%\js"
if not exist "%TARGET_DIR%\js\config" mkdir "%TARGET_DIR%\js\config"
if not exist "%TARGET_DIR%\js\components" mkdir "%TARGET_DIR%\js\components"
if not exist "%TARGET_DIR%\js\utils" mkdir "%TARGET_DIR%\js\utils"

echo.
echo Copying CSS files...
copy /Y "%SOURCE_DIR%\css\*.css" "%TARGET_DIR%\css\"

echo.
echo Copying JS files...
copy /Y "%SOURCE_DIR%\js\config.js" "%TARGET_DIR%\js\"
copy /Y "%SOURCE_DIR%\js\config\*.js" "%TARGET_DIR%\js\config\"
copy /Y "%SOURCE_DIR%\js\components\*.js" "%TARGET_DIR%\js\components\"
copy /Y "%SOURCE_DIR%\js\utils\*.js" "%TARGET_DIR%\js\utils\"
copy /Y "%SOURCE_DIR%\js\recruitment-process.js" "%TARGET_DIR%\js\"
copy /Y "%SOURCE_DIR%\js\recruitment-dashboard.js" "%TARGET_DIR%\js\"
copy /Y "%SOURCE_DIR%\js\recruitment-dashboard-new.js" "%TARGET_DIR%\js\"

echo.
echo Copying HTML files...
copy /Y "%SOURCE_DIR%\recruitment-process.html" "%TARGET_DIR%\"
copy /Y "%SOURCE_DIR%\recruitment-dashboard.html" "%TARGET_DIR%\"
copy /Y "%SOURCE_DIR%\integrated-applications.html" "%TARGET_DIR%\"
copy /Y "%SOURCE_DIR%\booking-management.html" "%TARGET_DIR%\"
copy /Y "%SOURCE_DIR%\interview-status.html" "%TARGET_DIR%\"
copy /Y "%SOURCE_DIR%\login-new.html" "%TARGET_DIR%\"
copy /Y "%SOURCE_DIR%\candidate-form-complete.html" "%TARGET_DIR%\"

echo.
echo ==========================================
echo Done!
echo ==========================================
echo.
echo Next steps:
echo 1. Open GitHub Desktop or command line
echo 2. Go to: %TARGET_DIR%
echo 3. Run: git add .
echo 4. Run: git commit -m "Organize files"
echo 5. Run: git push origin main
echo.
pause
