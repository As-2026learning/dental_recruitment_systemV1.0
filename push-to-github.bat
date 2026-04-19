@echo off
chcp 65001 >nul
echo ==========================================
echo   Push to GitHub
echo ==========================================
echo.

cd /d D:\GitHub\dental_recruitment_systemV2.0

echo Current directory: %cd%
echo.

echo Step 1: Initialize git repository...
git init

echo.
echo Step 2: Add all files...
git add .

echo.
echo Step 3: Commit files...
git commit -m "Organize file directory structure"

echo.
echo Step 4: Set branch name...
git branch -M main

echo.
echo Step 5: Add remote repository...
git remote add origin https://github.com/As-2026learning/dental_recruitment_systemV2.0.git 2>nul

echo.
echo Step 6: Push to GitHub...
git push -f origin main

echo.
echo ==========================================
echo Done!
echo ==========================================
echo.
echo Please wait 1-2 minutes for GitHub Pages to deploy.
echo.
pause
