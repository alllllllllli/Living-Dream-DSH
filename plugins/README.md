# DSH 插件安装指南

## 已安装插件清单

| 插件 | 版本 | 说明 |
|------|------|------|
| `billion-context-dsh` | 0.2.1 | ⚠️ 必须锁版本，默认误解析为 0.1.7 |
| `dsh-rss` | 0.2.0 | RSS 订阅管理 |
| `dsh-calendar` | 0.3.2 | 日历管理（CalDAV） |
| `dsh-email` | 0.6.2 | 邮件收发 |
| `dsh-ffmpeg` | 0.1.0 | 视频处理 |
| `@xiaweiliang060035/dsh-opencode-go-usage` | ^0.3.0 | OpenCode Go 用量悬浮球 |
| `@anionex/dsh-vision-toolkit` | ^0.1.8 | 视觉工具包 |
| `@dsh-community/dsh-paste-input` | ^0.1.0 | 文件拖拽上传（自研） |
| `dsh-model-router` | github:tianji-qingtian/dsh-model-router#v0.8.1 | 模型路由（不在 npm） |

## 安装方法

### 正确方式 ✅

```powershell
# 使用 dsh 官方命令安装
dsh plugin --profile web add <包名>@<版本>

# 示例
dsh plugin --profile web add billion-context-dsh@0.2.1
dsh plugin --profile web add dsh-rss@0.2.0
dsh plugin --profile web add dsh-calendar@0.3.2
dsh plugin --profile web add dsh-email@0.6.2
dsh plugin --profile web add dsh-ffmpeg@0.1.0
dsh plugin --profile web add @xiaweiliang060035/dsh-opencode-go-usage@0.3.0
dsh plugin --profile web add @anionex/dsh-vision-toolkit@0.1.8
dsh plugin --profile web add github:tianji-qingtian/dsh-model-router#v0.8.1
```

### 错误方式 ❌

```powershell
# ❌ 不要直接在 profile 目录跑 pnpm add/install
cd $env:USERPROFILE\.dsh\profiles\web
pnpm add <包名>  # 这会清掉未列出的 bundle！
```

## 自研插件：dsh-file-uploads

### 安装

```powershell
# 1. 克隆插件源码
git clone https://github.com/l541402398/dsh-file-uploads.git <YOUR_PLUGIN_DIR>\dsh-file-uploads

# 2. 创建 Junction（可选，用于开发）
New-Item -ItemType Junction -Path "D:/Tools/dsh-plugins/dsh-file-uploads" -Target "D:\workspace\dsh-file-uploads"

# 3. 在 package.json 中添加依赖
# "@dsh-community/dsh-paste-input": "file:D:/Tools/dsh-plugins/dsh-paste-input"

# 4. 安装
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install

# 5. 重启 DSH 桌面版 + 刷新页面
```

### 功能

- 支持任意文件拖拽到 Web GUI
- 支持 Ctrl+V 粘贴文件
- 上传到 `~/.dsh/uploads`
- 以『上传文件：`路径`』行注入提示词
- 防卡死机制（3 秒定时器 + 失焦重置）

## 故障排查

### 插件安装后不生效

1. 检查 `package.json` 的 `dsh.profile.bundles` 是否包含插件
2. 重启 DSH 桌面版（后端需要重启才生效）
3. 刷新浏览器页面

### billion-context-dsh 版本问题

```powershell
# 检查当前版本
dsh plugin --profile web list

# 如果是 0.1.7，强制更新到 0.2.1
dsh plugin --profile web add billion-context-dsh@0.2.1
```

### 桌面版打不开

```powershell
# 检查后端日志
Get-Content "$env:USERPROFILE\.dsh\logs\*.log" -Tail 50

# 常见错误：cannot resolve profile bundle
# 原因：package.json 中的 bundle 在 dependencies 中找不到
# 解决：重新安装缺失的插件
```
