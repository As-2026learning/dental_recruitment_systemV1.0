# 修复 GitHub Pages 部署问题
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  修复 GitHub Pages 部署问题" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$sourceDir = "D:\义齿工厂招聘小助手"
$targetDir = "D:\GitHub\dental_recruitment_systemV2.0"

# 步骤 1: 清理并创建目录
Write-Host "[1/5] 清理旧的 GitHub 目录..." -ForegroundColor Yellow
if (Test-Path $targetDir) {
    Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "    已删除旧目录"
}
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Write-Host "    已创建新目录: $targetDir"

# 步骤 2: 创建目录结构
Write-Host ""
Write-Host "[2/5] 创建目录结构..." -ForegroundColor Yellow
$dirs = @(
    "$targetDir\css",
    "$targetDir\js",
    "$targetDir\js\config",
    "$targetDir\js\components",
    "$targetDir\js\utils"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "    目录结构创建完成"

# 步骤 3: 复制 CSS 文件
Write-Host ""
Write-Host "[3/5] 复制 CSS 文件..." -ForegroundColor Yellow
$cssFiles = Get-ChildItem -Path "$sourceDir\css" -Filter "*.css" -ErrorAction SilentlyContinue
foreach ($file in $cssFiles) {
    Copy-Item -Path $file.FullName -Destination "$targetDir\css\" -Force
    Write-Host "    已复制: $($file.Name)"
}

# 步骤 4: 复制 JS 文件
Write-Host ""
Write-Host "[4/5] 复制 JS 文件..." -ForegroundColor Yellow

# 主目录 JS
$jsRootFiles = @("config.js", "recruitment-process.js", "recruitment-dashboard.js", "recruitment-dashboard-new.js")
foreach ($file in $jsRootFiles) {
    $sourcePath = "$sourceDir\js\$file"
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination "$targetDir\js\" -Force
        Write-Host "    已复制: js\$file"
    }
}

# 子目录 JS
$jsSubDirs = @("config", "components", "utils")
foreach ($subDir in $jsSubDirs) {
    $sourcePath = "$sourceDir\js\$subDir"
    $targetPath = "$targetDir\js\$subDir"
    if (Test-Path $sourcePath) {
        $files = Get-ChildItem -Path $sourcePath -Filter "*.js" -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            Copy-Item -Path $file.FullName -Destination $targetPath -Force
            Write-Host "    已复制: js\$subDir\$($file.Name)"
        }
    }
}

# 步骤 5: 复制 HTML 文件
Write-Host ""
Write-Host "[5/5] 复制 HTML 文件..." -ForegroundColor Yellow
$htmlFiles = Get-ChildItem -Path $sourceDir -Filter "*.html" -ErrorAction SilentlyContinue
foreach ($file in $htmlFiles) {
    Copy-Item -Path $file.FullName -Destination $targetDir -Force
    Write-Host "    已复制: $($file.Name)"
}

# 验证目录结构
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "文件组织完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "目录结构验证:" -ForegroundColor Cyan

$cssCount = (Get-ChildItem -Path "$targetDir\css" -Filter "*.css" -ErrorAction SilentlyContinue).Count
Write-Host "  css\ 目录: $cssCount 个文件"

$jsCount = 0
$jsCount += (Get-ChildItem -Path "$targetDir\js" -Filter "*.js" -ErrorAction SilentlyContinue).Count
$jsCount += (Get-ChildItem -Path "$targetDir\js\config" -Filter "*.js" -ErrorAction SilentlyContinue).Count
$jsCount += (Get-ChildItem -Path "$targetDir\js\components" -Filter "*.js" -ErrorAction SilentlyContinue).Count
$jsCount += (Get-ChildItem -Path "$targetDir\js\utils" -Filter "*.js" -ErrorAction SilentlyContinue).Count
Write-Host "  js\ 目录: $jsCount 个文件"

$htmlCount = (Get-ChildItem -Path $targetDir -Filter "*.html" -ErrorAction SilentlyContinue).Count
Write-Host "  HTML 文件: $htmlCount 个"

# 推送到 GitHub
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "推送到 GitHub..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $targetDir

Write-Host "[6/8] 初始化 Git 仓库..." -ForegroundColor Yellow
git init

Write-Host ""
Write-Host "[7/8] 添加并提交文件..." -ForegroundColor Yellow
git add .
git commit -m "Fix: Organize files into correct directory structure (css/, js/, etc.)"

Write-Host ""
Write-Host "[8/8] 推送到 GitHub..." -ForegroundColor Yellow
git branch -M main
git remote remove origin 2>$null
git remote add origin https://github.com/As-2026learning/dental_recruitment_systemV2.0.git
git push -f origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "✅ 推送成功！" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "请等待 2-3 分钟让 GitHub Pages 重新部署。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "然后访问:" -ForegroundColor Cyan
    Write-Host "  https://as-2026learning.github.io/dental_recruitment_systemV2.0/recruitment-process.html"
    Write-Host "  https://as-2026learning.github.io/dental_recruitment_systemV2.0/recruitment-dashboard.html"
} else {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "❌ 推送失败" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "请检查网络连接，或手动执行以下命令:" -ForegroundColor Yellow
    Write-Host "  cd D:\GitHub\dental_recruitment_systemV2.0"
    Write-Host "  git push -f origin main"
}

Write-Host ""
Read-Host "按 Enter 键退出"
