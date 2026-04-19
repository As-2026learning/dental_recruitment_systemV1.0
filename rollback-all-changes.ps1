# 一键回滚所有修改
Write-Host "🔄 开始回滚所有修改..." -ForegroundColor Yellow

$files = @(
    @{Original="auth.js"; Backup="auth.js.backup.20260418"},
    @{Original="login-new.html"; Backup="login-new.html.backup.20260418"},
    @{Original="admin-standalone.html"; Backup="admin-standalone.html.backup.20260418"},
    @{Original="integrated-applications.html"; Backup="integrated-applications.html.backup.20260418"},
    @{Original="recruitment-process.html"; Backup="recruitment-process.html.backup.20260418"},
    @{Original="settings.html"; Backup="settings.html.backup.20260418"},
    @{Original="permissions.html"; Backup="permissions.html.backup.20260418"},
    @{Original="recruitment-dashboard.html"; Backup="recruitment-dashboard.html.backup.20260418"}
)

$successCount = 0
$failCount = 0

foreach ($file in $files) {
    $original = $file.Original
    $backup = $file.Backup
    
    if (Test-Path $backup) {
        try {
            Copy-Item $backup $original -Force
            Write-Host "✅ 已恢复: $original" -ForegroundColor Green
            $successCount++
        } catch {
            Write-Host "❌ 恢复失败: $original - $_" -ForegroundColor Red
            $failCount++
        }
    } else {
        Write-Host "⚠️ 备份不存在: $backup" -ForegroundColor Yellow
        $failCount++
    }
}

Write-Host ""
Write-Host "📊 回滚结果：" -ForegroundColor Cyan
Write-Host "   成功: $successCount" -ForegroundColor Green
Write-Host "   失败: $failCount" -ForegroundColor Red
Write-Host ""
Write-Host "🎉 回滚完成！请刷新浏览器测试。" -ForegroundColor Green
Write-Host ""
if ($failCount -gt 0) {
    Write-Host "⚠️ 部分文件恢复失败，请手动检查备份文件。" -ForegroundColor Yellow
}
