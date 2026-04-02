# 启动本地 HTTP 服务器
$port = 9090
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "Server started at http://localhost:$port/"
Write-Host "Press Ctrl+C to stop the server"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # 获取请求的路径
        $path = $request.Url.LocalPath
        if ($path -eq "/") {
            $path = "/index.html"
        }
        
        # 构建文件路径
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath $path.TrimStart("/")
        
        # 检查文件是否存在
        if (Test-Path -Path $filePath -PathType Leaf) {
            # 读取文件内容
            $content = Get-Content -Path $filePath -Raw -Encoding UTF8
            
            # 设置内容类型
            $extension = [System.IO.Path]::GetExtension($filePath)
            $contentType = switch ($extension) {
                ".html" { "text/html" }
                ".css" { "text/css" }
                ".js" { "text/javascript" }
                ".json" { "application/json" }
                ".png" { "image/png" }
                ".jpg" { "image/jpeg" }
                ".ico" { "image/x-icon" }
                default { "application/octet-stream" }
            }
            
            $response.ContentType = $contentType
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } else {
            # 文件不存在，返回 404
            $response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("<h1>404 Not Found</h1>")
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)"
} finally {
    $listener.Stop()
    Write-Host "Server stopped"
}
