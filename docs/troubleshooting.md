# DSH 故障排查手册

## 常见问题

### 1. 桌面版打不开

**症状**：双击 exe 无反应，或闪退

**排查步骤**：

```powershell
# 1. 检查进程是否已存在
Get-Process -Name "DeepSeek Harness*"

# 2. 检查端口占用
Get-NetTCPConnection -State Listen | Where-Object {$_.LocalAddress -eq '127.0.0.1'}

# 3. 查看日志
Get-Content "$env:USERPROFILE\.dsh\logs\*.log" -Tail 100

# 4. 检查 Node.js 是否正常
node --version
```

**常见原因**：
- 端口被占用（杀掉旧进程）
- 插件加载失败（检查 package.json）
- Node.js 版本不兼容

---

### 2. 插件安装后不生效

**症状**：安装插件后功能未出现

**排查步骤**：

```powershell
# 1. 检查插件是否在 bundles 中
Get-Content "$env:USERPROFILE\.dsh\profiles\web\package.json" | ConvertFrom-Json | Select-Object -ExpandProperty dsh

# 2. 检查 node_modules 是否有插件
Get-ChildItem "$env:USERPROFILE\.dsh\profiles\web\node_modules" -Directory | Where-Object {$_.Name -like "*dsh*"}

# 3. 检查后端日志
Get-Content "$env:USERPROFILE\.dsh\logs\*.log" -Tail 50 | Select-String "bundle|plugin"
```

**解决方案**：
- 重启 DSH 桌面版（后端需要重启）
- 刷新浏览器页面
- 检查 package.json 的 dependencies 和 bundles 是否一致

---

### 3. billion-context-dsh 版本错误

**症状**：后端启动报 `cannot resolve profile bundle`

**原因**：默认安装的是 0.1.7，没有 dsh.bundle

**解决**：

```powershell
# 强制安装正确版本
dsh plugin --profile web add billion-context-dsh@0.2.1

# 验证
dsh plugin --profile web list | Select-String "billion"
```

---

### 4. MCP 服务器启动失败

**症状**：工具调用超时或报错

**排查步骤**：

```powershell
# 1. 检查 MCP 服务器是否能独立运行
python %USERPROFILE%\dsh-workspace\memory-mcp\server.py

# 2. 检查 Python 环境
python --version
pip list | Select-String "mcp"

# 3. 检查 cordis.patch.yml 配置
Get-Content "$env:USERPROFILE\.dsh\profiles\web\cordis.patch.yml" | Select-String "command|args"
```

**常见原因**：
- Python 路径错误
- 依赖未安装
- 端口被占用

---

### 5. CNB 代理无法连接

**症状**：DSH 无法调用 CNB 模型

**排查步骤**：

```powershell
# 1. 检查代理是否运行
netstat -an | findstr ":8800"

# 2. 测试代理
curl http://127.0.0.1:8800/v1/models

# 3. 检查 API Key
Get-Content "$env:USERPROFILE\.dsh\.credentials.yaml" | Select-String "CNB_API_KEY"

# 4. 查看代理日志
Get-Content "cnb_proxy.log" -Tail 50
```

**解决方案**：
- 重启代理：`python cnb_proxy.py --port 8800`
- 检查 CNB 账号是否有效
- 检查网络连接

---

### 6. 手机远程访问失败

**症状**：手机浏览器报 ERR_CONNECTION_ABORTED

**原因**：node stdout 缓冲写满

**解决**：

```powershell
# 1. 杀掉旧代理进程
Get-Process -Name "node" | Where-Object {$_.CommandLine -like "*proxy.js*"} | Stop-Process -Force

# 2. 重启计划任务
Start-ScheduledTask -TaskName "DSH Phone Proxy"

# 3. 检查代理日志
Get-Content "D:\workspace\dsh-phone\proxy.log" -Tail 50
```

---

### 7. 发图不自动识别

**症状**：发图后没有生成描述文件

**排查步骤**：

```powershell
# 1. 检查补丁是否生效
Get-Content "%DSH_DESKTOP_PATH%\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" | Select-String "describeImagesLocally"

# 2. 检查视觉配置
Get-Content "%USERPROFILE%\dsh-workspace\dsh_vision_config.json"

# 3. 测试 API 连通性
python %USERPROFILE%\dsh-workspace\test_vision_zhipu.py
```

**解决方案**：
- 重打补丁（DSH 升级会覆盖）
- 检查 API Key 是否有效
- 检查网络连接

---

### 8. 密钥解密失败

**症状**：secrets.ps1 报错

**排查步骤**：

```powershell
# 1. 检查 secrets.json 是否存在
Test-Path "$env:USERPROFILE\.dsh\secrets.json"

# 2. 检查 DPAPI 是否正常
powershell -File "$env:USERPROFILE\.dsh\secrets.ps1" -Name "test"
```

**解决方案**：
- 重新生成 secrets.json
- 确保在当前用户账号下运行

---

## 性能优化

### 1. 减少日志输出

```powershell
# 在 settings.yaml 中添加
logging:
  level: warn
```

### 2. 禁用不需要的 MCP

在 `cordis.patch.yml` 中注释掉不需要的 MCP 配置。

### 3. 清理上传文件

```powershell
# 清理旧的上传文件
Get-ChildItem "$env:USERPROFILE\.dsh\uploads" -Recurse | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Recurse -Force
```

## 获取帮助

- GitHub Issues: https://github.com/alllllllllli/Living-Dream-DSH/issues
- DSH 官方文档: https://github.com/deepseek-ai/deepseek-harness
- DSH Handbook: https://github.com/Electricitysheep/dsh-handbook
