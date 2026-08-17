# 手机远程访问 DSH 教程

通过 Tailscale 实现手机浏览器访问电脑上的 DSH。

## 架构

```
手机浏览器
    ↓ HTTPS
Tailscale Serve (443)
    ↓ HTTP
改写代理 (127.0.0.1:8090)
    ↓ HTTP
DSH 桌面版 (127.0.0.1:3080)
```

## 前置条件

- 电脑和手机安装 Tailscale
- 同一 Tailscale 账号
- DSH 桌面版已启动

## 安装步骤

### 1. 安装 Tailscale

```powershell
# Windows
winget install tailscale.tailscale

# 或从 https://tailscale.com/download 下载
```

### 2. 登录 Tailscale

```powershell
# 电脑端
tailscale up

# 手机端：下载 Tailscale App 并登录同一账号
```

### 3. 配置 Serve

```powershell
# 配置 HTTPS 服务（后台运行）
tailscale serve --https=443 --bg http://127.0.0.1:3080

# 查看当前配置
tailscale serve status
```

### 4. 手机访问

在手机浏览器访问：
```
https://<你的设备名>.<你的域名>.ts.net
```

例如：
```
https://desktop-or1ha06.tailea2f65.ts.net
```

## 改写代理（解决跨域问题）

DSH 的 Web UI 有跨域检查，需要改写请求头。创建 `proxy.js`：

```javascript
const http = require('http');
const httpProxy = require('http-proxy');

const proxy = httpProxy.createProxyServer({
  target: 'http://127.0.0.1:3080',
  ws: true
});

const server = http.createServer((req, res) => {
  // 改写请求头
  req.headers['host'] = '127.0.0.1:3080';
  req.headers['origin'] = 'http://127.0.0.1:3080';
  req.headers['sec-fetch-site'] = 'same-origin';
  
  proxy.web(req, res);
});

// WebSocket 支持
server.on('upgrade', (req, socket, head) => {
  req.headers['host'] = '127.0.0.1:3080';
  req.headers['origin'] = 'http://127.0.0.1:3080';
  proxy.ws(req, socket, head);
});

server.listen(8090, '127.0.0.1', () => {
  console.log('Proxy listening on 127.0.0.1:8090');
});
```

启动代理：
```powershell
node proxy.js
```

然后修改 Tailscale serve 指向代理：
```powershell
tailscale serve --https=443 --bg http://127.0.0.1:8090
```

## 持久化配置

### 方案 1：计划任务

```powershell
# 创建计划任务（登录时自动启动）
$action = New-ScheduledTaskAction -Execute "node.exe" -Argument "D:\path\to\proxy.js"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "DSH Phone Proxy" -Action $action -Trigger $trigger -Settings $settings
```

### 方案 2：开机自启

```powershell
# 添加到注册表 Run 项
# 请根据实际安装路径修改
$dshExe = "D:\Tools\DeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
  -Name "DeepSeekHarness" `
  -Value $dshExe
```

## 故障排查

### 手机报 ERR_CONNECTION_ABORTED

**原因**：node stdout 缓冲写满（隐藏窗口中无人读取）

**解决**：重定向 stdout 到文件

```javascript
// 在 proxy.js 开头添加
const fs = require('fs');
const logStream = fs.createWriteStream('proxy.log', { flags: 'a' });
process.stdout.write = process.stderr.write = logStream.write.bind(logStream);
```

### 5G 网络不稳定

**原因**：走香港 DERP 中转

**解决**：使用 Wi-Fi 直连最稳

### 查看当前端口

```powershell
# 查找 DSH 监听的端口
Get-NetTCPConnection -State Listen | Where-Object {$_.LocalAddress -eq '127.0.0.1'} | 
  Select-Object LocalPort, OwningProcess | 
  ForEach-Object { $_ | Add-Member -NotePropertyName ProcessName -NotePropertyValue (Get-Process -Id $_.OwningProcess).ProcessName -PassThru } |
  Where-Object {$_.ProcessName -eq 'node'}
```

## 安全注意事项

- Tailscale 使用 WireGuard 加密，安全性高
- 不要暴露到公网
- 定期更新 Tailscale
