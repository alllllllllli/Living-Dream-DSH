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

> ⚠️ 必须先启动改写代理（见下方「改写代理」章节），直连 3080 会因 CORS 失败。

```powershell
# 配置 HTTPS 服务（指向 8090 代理，不是 3080）
tailscale serve --https=443 --bg http://127.0.0.1:8090

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

DSH 的 Web UI 有跨域检查，需要改写请求头。仓库已内置 `scripts/proxy.js`，直接使用：

```powershell
# 首次需安装依赖
npm install http-proxy

# 启动代理
node scripts/proxy.js
```

代理代码见 [`scripts/proxy.js`](../scripts/proxy.js)。

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
# 请根据实际安装路径修改（或设置 DSH_DESKTOP_PATH 环境变量）
$dshDir = if ($env:DSH_DESKTOP_PATH) { $env:DSH_DESKTOP_PATH } else { "D:\Tools\DeepSeekHarness-Desktop" }
$dshExe = Get-ChildItem "$dshDir\*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.FullName }
if (-not $dshExe) { Write-Error "DSH Desktop not found in $dshDir"; exit 1 }
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
