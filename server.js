const http = require('http');
const fs = require('fs');
const path = require('path');

const port = 3000;
const publicDirectory = __dirname;

const server = http.createServer((req, res) => {
  let filePath = path.join(publicDirectory, req.url === '/' ? 'application.html' : req.url);
  
  // 检查文件是否存在
  if (!fs.existsSync(filePath)) {
    res.statusCode = 404;
    res.setHeader('Content-Type', 'text/html');
    res.end('<h1>404 Not Found</h1>');
    return;
  }
  
  // 检查是否是目录
  if (fs.statSync(filePath).isDirectory()) {
    filePath = path.join(filePath, 'index.html');
  }
  
  // 读取文件
  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.statusCode = 500;
      res.setHeader('Content-Type', 'text/html');
      res.end('<h1>500 Internal Server Error</h1>');
      return;
    }
    
    // 设置内容类型
    const extname = path.extname(filePath);
    let contentType = 'text/html';
    
    switch (extname) {
      case '.js':
        contentType = 'text/javascript';
        break;
      case '.css':
        contentType = 'text/css';
        break;
      case '.json':
        contentType = 'application/json';
        break;
      case '.png':
        contentType = 'image/png';
        break;
      case '.jpg':
        contentType = 'image/jpg';
        break;
      case '.ico':
        contentType = 'image/x-icon';
        break;
    }
    
    res.statusCode = 200;
    res.setHeader('Content-Type', contentType);
    res.end(content, 'utf-8');
  });
});

server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
