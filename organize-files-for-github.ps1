# ============================================
# File Organization Script
# ============================================

$targetDir = "D:\GitHub\dental_recruitment_systemV2.0"
$sourceDir = "D:\义齿工厂招聘小助手"

Write-Host "Creating directories..."

New-Item -ItemType Directory -Force -Path "$targetDir\css" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetDir\js" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetDir\js\config" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetDir\js\components" | Out-Null
New-Item -ItemType Directory -Force -Path "$targetDir\js\utils" | Out-Null

Write-Host "Copying CSS files..."
Copy-Item "$sourceDir\css\*.css" "$targetDir\css\" -Force

Write-Host "Copying JS config files..."
Copy-Item "$sourceDir\js\config.js" "$targetDir\js\" -Force
Copy-Item "$sourceDir\js\config\*.js" "$targetDir\js\config\" -Force

Write-Host "Copying JS component files..."
Copy-Item "$sourceDir\js\components\*.js" "$targetDir\js\components\" -Force

Write-Host "Copying JS utility files..."
Copy-Item "$sourceDir\js\utils\*.js" "$targetDir\js\utils\" -Force

Write-Host "Copying JS page files..."
Copy-Item "$sourceDir\js\recruitment-process.js" "$targetDir\js\" -Force
Copy-Item "$sourceDir\js\recruitment-dashboard.js" "$targetDir\js\" -Force
Copy-Item "$sourceDir\js\recruitment-dashboard-new.js" "$targetDir\js\" -Force

Write-Host "Copying HTML files..."
Copy-Item "$sourceDir\recruitment-process.html" "$targetDir\" -Force
Copy-Item "$sourceDir\recruitment-dashboard.html" "$targetDir\" -Force
Copy-Item "$sourceDir\integrated-applications.html" "$targetDir\" -Force
Copy-Item "$sourceDir\booking-management.html" "$targetDir\" -Force
Copy-Item "$sourceDir\interview-status.html" "$targetDir\" -Force
Copy-Item "$sourceDir\login-new.html" "$targetDir\" -Force
Copy-Item "$sourceDir\candidate-form-complete.html" "$targetDir\" -Force

Write-Host "Done!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. cd $targetDir"
Write-Host "2. git add ."
Write-Host "3. git commit -m 'Organize files'"
Write-Host "4. git push origin main"

pause
