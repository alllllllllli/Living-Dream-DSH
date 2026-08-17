# Living Dream DSH 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-config-4f46e5)](https://github.com/deepseek-ai/deepseek-harness)

**Living Dream DSH — 一站式 DeepSeek Harness 桌面版终极配置方案**

一套经过实战验证的 DSH 配置框架，集成了 8+ MCP 服务器、自研插件、免费模型渠道、手机远程访问等完整方案。

> 📖 [English](README.md) | [简体中文](README.zh.md)

---

## 🆚 Living Dream DSH vs Claude Code

| 特性 | Living Dream DSH | Claude Code |
|------|------------------|-------------|
| **模型** | DeepSeek V4 (免费) | Claude (付费) |
| **免费额度** | ✅ CNB 代理免费、AMD Radeon 免费 | ❌ 需付费 |
| **MCP 服务器** | ✅ 8+ 个开箱即用（桌面操作/浏览器/OCR/记忆等） | ✅ 原生支持（自行配置） |
| **桌面自动化** | ✅ 截图/点击/键鼠控制 | ⚠️ computer use（Beta） |
| **浏览器控制** | ✅ Playwright 自动化 | ⚠️ computer use（Beta） |
| **手机远程访问** | ✅ Tailscale 方案 | ❌ 无 |
| **图片识别** | ✅ GLM-4V-Flash 免费 | ✅ 原生支持 |
| **文件拖拽上传** | ✅ 自研插件 | ❌ 无 |
| **长期记忆** | ✅ 语义检索 | ✅ CLAUDE.md/记忆文件 |
| **文档转换** | ✅ MarkItDown | ❌ 无 |
| **屏幕 OCR** | ✅ Windows OCR | ⚠️ computer use |
| **开源** | ✅ MIT 许可证 | ❌ 闭源 |
| **价格** | 🆓 免费 | 💰 $20/月起 |

**为什么选择 Living Dream DSH？**

1. **零成本**：通过 CNB 代理和 AMD Radeon Cloud，完全免费使用 DeepSeek V4
2. **全栈能力**：不只是写代码，还能操作桌面、控制浏览器、识别图片
3. **移动办公**：手机浏览器随时随地访问
4. **开源透明**：MIT 许可证，可自由修改和扩展

---

## ✨ 特性一览

| 功能 | 说明 |
|------|------|
| 🔌 **8+ MCP 服务器** | 历史/视觉/桌面操作/代码执行/浏览器/记忆/文档转换/OCR |
| 🤖 **免费模型渠道** | CNB 代理（DeepSeek V4 免费）+ AMD Radeon Cloud |
| 📱 **手机远程访问** | Tailscale + 改写代理，手机浏览器操作 DSH |
| 🖼️ **发图自动识别** | GLM-4V-Flash 免费视觉描述（仅桌面版） |
| 📁 **文件拖拽上传** | 自研 dsh-file-uploads 插件 |
| 🔐 **密钥存储** | 本地 `~/.dsh/.credentials.yaml`（安装时掩码输入）|
| 🛡️ **防坑指南** | 踩过的坑和解决方案全记录 |

---

## 📁 目录结构

```
Living-Dream-DSH/
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
│   ├── start-dsh.bat.template      # 启动器模板
│   ├── os-copilot-mcp-server.py    # OS-Copilot MCP 服务器
│   └── os-copilot-mcp-README.md    # OS-Copilot MCP 说明
├── plugins/
│   └── README.md                   # 插件安装说明
└── docs/
    ├── phone-remote.md             # 手机远程访问教程
    ├── vision-patch.md             # 发图改造教程
    └── troubleshooting.md          # 故障排查手册
```

---

## 🚀 快速开始

### 前置条件（必须先安装）

| 软件 | 版本 | 下载地址 | 必装？ |
|------|------|----------|--------|
| **DeepSeek Harness 桌面版** | v1.1.0+ | [GitHub Releases](https://github.com/deepseek-ai/deepseek-harness/releases) | ✅ 必装 |
| **Node.js** | v22+（推荐 v24 LTS） | [nodejs.org](https://nodejs.org/) | ✅ 必装 |
| **Python** | 3.13+ | [python.org](https://python.org/) | ✅ 必装 |
| **pnpm** | 最新版 | `npm install -g pnpm` | ✅ 必装 |
| **Git** | 任意版本 | [git-scm.com](https://git-scm.com/) | 克隆用 |

### 方式一：一键安装（推荐）

```powershell
# 1. 克隆仓库
git clone https://github.com/alllllllllli/Living-Dream-DSH.git
cd Living-Dream-DSH

# 2. 双击运行 install.bat
#    或在 PowerShell 中执行：.\install.ps1
```

安装程序会自动：
- ✅ 检查环境（Node.js、Python、pnpm）
- ✅ 复制配置文件到 `~/.dsh`
- ✅ 交互式填入 API Key
- ✅ 安装插件依赖
- ✅ 创建桌面快捷方式

### 方式二：手动安装

<details>
<summary>点击展开手动安装步骤</summary>

#### 详细步骤

```powershell
# 1. 安装前置软件（如果未安装）
winget install OpenJS.NodeJS.LTS        # Node.js
winget install Python.Python.3.13       # Python
npm install -g pnpm                      # pnpm

# 2. 克隆仓库
git clone https://github.com/alllllllllli/Living-Dream-DSH.git
cd Living-Dream-DSH

# 3. 复制配置文件到 DSH 目录
Copy-Item configs\cordis.patch.yml.template $env:USERPROFILE\.dsh\profiles\web\cordis.patch.yml
Copy-Item configs\package.json.template $env:USERPROFILE\.dsh\profiles\web\package.json
Copy-Item configs\settings.yaml.template $env:USERPROFILE\.dsh\settings.yaml
Copy-Item configs\AGENTS.md $env:USERPROFILE\.dsh\AGENTS.md
Copy-Item configs\.credentials.yaml.template $env:USERPROFILE\.dsh\.credentials.yaml

# 4. 编辑配置文件（填入你的 API Key）
notepad $env:USERPROFILE\.dsh\.credentials.yaml

# 5. 安装插件（dsh-paste-input 是 file: 依赖, 先克隆源码）
git clone https://github.com/l541402398/dsh-file-uploads.git $env:USERPROFILE\.dsh\plugins\dsh-paste-input
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install

# 6. 重启 DSH 桌面版
```

</details>

### 3. 配置 MCP 服务器

详见 [configs/README.md](configs/README.md)

---

## 🔌 MCP 服务器列表

| MCP | 功能 | 依赖 |
|-----|------|------|
| `dsh-history` | 历史会话查询/搜索 | Python + server.py |
| `dsh-vision` | 图片分析（Ollama qwen2.5vl） | Python + Ollama |
| `dsh-computer` | 桌面操作（截图/点击/键鼠） | @zavora-ai/computer-use-mcp (MIT) |
| `os-copilot` | 代码执行（Python/Shell/文件操作） | Python + server.py |
| `dsh-browser` | 浏览器自动化（Playwright） | Node.js + Edge 扩展 |
| `dsh-memory` | 长期记忆（语义检索） | Python + server.py |
| `dsh-markitdown` | 文档转 Markdown | Python + MarkItDown |
| `dsh-ocr` | 屏幕 OCR | Python + Windows OCR |

---

## 🤖 免费模型渠道

### CNB 代理（推荐）

> ⚠️ **硬前提**：代理需要一个你自己的 CNB **私有仓库**（在仓库里创建 Issue 让 NPC 回复，接口的 invisible 参数实际不生效，靠仓库私有兜底）。配置方法：在 `~/.dsh/.credentials.yaml` 写一行 `CNB_REPO: 你的组织/你的仓库`，或设置环境变量 `CNB_REPO`，或启动时 `--repo` 指定。一键安装脚本会在安装时询问。

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

# 3. 启动改写代理（必须先过 8090，DSH Web UI 有跨域检查，直连 3080 会报 CORS）
# 见 docs/phone-remote.md 里的 proxy.js 改写代理
node proxy.js   # 监听 127.0.0.1:8090

# 4. 配置 serve（指向 8090 代理，不是 3080）
tailscale serve --https=443 --bg http://127.0.0.1:8090

# 4. 手机浏览器访问
# https://<你的设备名>.<你的域名>.ts.net
```

详见 [docs/phone-remote.md](docs/phone-remote.md)

---

## 🖼️ 发图自动识别改造

让 DSH 桌面版发图时自动调用 GLM-4V-Flash 识别：

```powershell
# 1. 备份原文件
$dshPath = (Get-Process "DeepSeek Harness" -ErrorAction SilentlyContinue).Path
if (-not $dshPath) { $dshPath = "D:\Tools\DeepSeek-Harness-Desktop" }
Copy-Item "$dshPath\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" `
          "$env:USERPROFILE\dsh-host-apiproxy-index.js.bak"

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
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
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
