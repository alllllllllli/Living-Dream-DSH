# DSH Ultra Config 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-config-4f46e5)](https://github.com/deepseek-ai/deepseek-harness)

**一站式 DeepSeek Harness 桌面版终极配置方案**

一套经过实战验证的 DSH 配置框架，集成了 7+ MCP 服务器、自研插件、免费模型渠道、手机远程访问等完整方案。

> 📖 [English](README.md) | [简体中文](README.zh.md)

---

## ✨ 特性一览

| 功能 | 说明 |
|------|------|
| 🔌 **7+ MCP 服务器** | 历史/视觉/桌面操作/浏览器/记忆/文档转换/OCR |
| 🤖 **免费模型渠道** | CNB 代理（DeepSeek V4 免费）+ AMD Radeon Cloud |
| 📱 **手机远程访问** | Tailscale + 改写代理，手机浏览器操作 DSH |
| 🖼️ **发图自动识别** | GLM-4V-Flash 免费视觉描述（仅桌面版） |
| 📁 **文件拖拽上传** | 自研 dsh-file-uploads 插件 |
| 🔐 **密钥安全存储** | DPAPI 加密 + secrets.ps1 解密 |
| 🛡️ **防坑指南** | 踩过的坑和解决方案全记录 |

---

## 📁 目录结构

```
dsh-ultra-config/
├── README.md                    # 英文说明
├── README.zh.md                 # 中文说明
├── LICENSE                      # MIT 许可证
├── .gitignore
├── configs/
│   ├── cordis.patch.yml.template   # MCP 配置模板
│   ├── package.json.template       # 插件清单模板
│   ├── settings.yaml.template      # 全局设置模板
│   ├── AGENTS.md                   # AI 指令文件
│   └── .credentials.yaml.template  # API Key 模板
├── scripts/
│   ├── cnb_proxy.py                # CNB 代理（OpenAI 兼容）
│   ├── secrets.ps1                 # DPAPI 密钥解密
│   └── start-dsh.bat.template      # 启动器模板
├── plugins/
│   └── README.md                   # 插件安装说明
└── docs/
    ├── phone-remote.md             # 手机远程访问教程
    ├── vision-patch.md             # 发图改造教程
    └── troubleshooting.md          # 故障排查手册
```

---

## 🚀 快速开始

### 1. 环境要求

- Windows 10/11
- Node.js v22+ (推荐 v24 LTS)
- Python 3.13+ (用于 MCP 服务器)
- DeepSeek Harness 桌面版 v1.1.0+

### 2. 安装步骤

```powershell
# 克隆仓库
git clone https://github.com/alllllllllli/dsh-ultra-config.git
cd dsh-ultra-config

# 复制配置文件到 DSH 目录
Copy-Item configs\cordis.patch.yml.template $env:USERPROFILE\.dsh\profiles\web\cordis.patch.yml
Copy-Item configs\package.json.template $env:USERPROFILE\.dsh\profiles\web\package.json
Copy-Item configs\settings.yaml.template $env:USERPROFILE\.dsh\settings.yaml
Copy-Item configs\AGENTS.md $env:USERPROFILE\.dsh\AGENTS.md

# 编辑配置文件（填入你的 API Key）
notepad $env:USERPROFILE\.dsh\.credentials.yaml

# 安装插件
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install

# 重启 DSH 桌面版
```

### 3. 配置 MCP 服务器

详见 [configs/README.md](configs/README.md)

---

## 🔌 MCP 服务器列表

| MCP | 功能 | 依赖 |
|-----|------|------|
| `dsh-history` | 历史会话查询/搜索 | Python + server.py |
| `dsh-vision` | 图片分析（Ollama qwen2.5vl） | Python + Ollama |
| `dsh-computer` | 桌面操作（截图/点击/键鼠） | computer-use.exe |
| `dsh-browser` | 浏览器自动化（Playwright） | Node.js + Edge 扩展 |
| `dsh-memory` | 长期记忆（语义检索） | Python + server.py |
| `dsh-markitdown` | 文档转 Markdown | Python + MarkItDown |
| `dsh-ocr` | 屏幕 OCR | Python + Windows OCR |

---

## 🤖 免费模型渠道

### CNB 代理（推荐）

```powershell
# 启动 CNB 代理
python scripts\cnb_proxy.py --port 8800

# 或使用启动器（自动检测并启动）
scripts\start-dsh.bat
```

**支持模型：**
- `deepseek-v4-flash` - 免费至 2026-12-31
- `deepseek-v4-pro` - 每月 500 免费积分

### AMD Radeon Cloud

- 端点：`https://developer.amd.com.cn/radeon/api/v1`
- 模型：DeepSeek-V4-Flash
- 注册：developer.amd.com.cn/radeon

---

## 📱 手机远程访问

通过 Tailscale 实现手机浏览器访问 DSH：

```powershell
# 1. 安装 Tailscale
winget install tailscale.tailscale

# 2. 登录同一账号
tailscale up

# 3. 配置 serve
tailscale serve --https=443 --bg http://127.0.0.1:3080

# 4. 手机浏览器访问
# https://<你的设备名>.<你的域名>.ts.net
```

详见 [docs/phone-remote.md](docs/phone-remote.md)

---

## 🖼️ 发图自动识别改造

让 DSH 桌面版发图时自动调用 GLM-4V-Flash 识别：

```powershell
# 1. 备份原文件
Copy-Item "D:\ToolsDeepSeek-Harness-Desktop\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" `
          "G:\vision-files\dsh-host-apiproxy-index.js.bak"

# 2. 应用补丁（需手动修改 911 行附近的 describeImagesLocally 函数）
# 详见 docs/vision-patch.md
```

⚠️ **注意**：DSH 升级会覆盖此补丁，需重打。

---

## 🛡️ 防坑指南

### 1. 插件安装

```powershell
# ✅ 正确方式
dsh plugin --profile web add <包名>@<版本>

# ❌ 错误方式（会清掉未列出的 bundle）
cd $env:USERPROFILE\.dsh\profiles\web
pnpm add <包名>
```

### 2. 桌面版与 Dev 版冲突

两者共用 `~/.dsh`，有并发写冲突。使用桌面版时请关闭 Dev 版（3080 端口）。

### 3. 发图补丁

DSH 升级会覆盖 `dsh-host-apiproxy` 的修改，需重打补丁。

### 4. billion-context-dsh 版本

必须锁定版本 `0.2.1`，默认会误解析为 `0.1.7`（无 dsh.bundle）。

---

## 📝 配置文件说明

### cordis.patch.yml

MCP 服务器配置文件，位于 `~/.dsh/profiles/web/cordis.patch.yml`

```yaml
# 示例：添加一个 MCP 服务器
- insert:
    - id: mcp-dsh-example
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        transport: stdio
        serverName: dsh-example
        command: python
        args:
          - path/to/server.py
        env: {}
        cwd: ''
        toolCallTimeoutMs: 120000
        failOnStartupError: false
```

### settings.yaml

全局设置文件，位于 `~/.dsh/settings.yaml`

```yaml
# 配置模型提供商
llm-pi-ai:
  providers:
    my-provider:
      apiKeyEnv: MY_API_KEY
      api: openai-completions
      baseURL: https://api.example.com/v1
      models:
        - id: my-model
          name: My Model
          contextWindow: 1000000
```

### .credentials.yaml

API Key 存储文件，位于 `~/.dsh/.credentials.yaml`

```yaml
MY_API_KEY: sk-xxxxxxxxxxxx
```

---

## 🔧 自定义扩展

### 添加新的 MCP 服务器

1. 创建 MCP 服务器（参考现有实现）
2. 在 `cordis.patch.yml` 中添加配置
3. 在 `package.json` 的 bundles 中添加插件（如果需要）
4. 重启 DSH 桌面版

### 创建自定义插件

参考 [dsh-file-uploads](https://github.com/l541402398/dsh-file-uploads) 插件结构。

---

## 📚 相关资源

- [DeepSeek Harness 官方仓库](https://github.com/deepseek-ai/deepseek-harness)
- [DSH Handbook](https://github.com/Electricitysheep/dsh-handbook)
- [Playwright MCP](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo)
- [MarkItDown](https://github.com/microsoft/markitdown)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

---

## 🙏 致谢

- [DeepSeek](https://www.deepseek.com/) - 提供 DSH 框架
- [l541402398](https://github.com/l541402398) - dsh-file-uploads 插件原作者
- [CNB](https://cnb.cool/) - 免费 API 渠道
- [智谱 AI](https://open.bigmodel.cn/) - GLM-4V-Flash 视觉模型

---

**最后更新**：2026-08-17
