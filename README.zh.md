# Living Dream DSH 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-config-4f46e5)](https://github.com/deepseek-ai/deepseek-harness)

**Living Dream DSH — 一站式 DeepSeek Harness 桌面版终极配置方案**

一套经过实战验证的 DSH 配置框架，集成了 8+ MCP 服务器、自研插件、免费模型渠道、手机远程访问等完整方案。

> 📖 [English](README.md) | [简体中文](README.zh.md)

---

## 🆚 Living Dream DSH vs 主流 AI 编程框架

> 数据截至 2026-08，价格以各官方页面为准。Living-Dream-DSH 为基于 DeepSeek Harness 的开源配置整合包（MIT 许可证）。

### 总览对比表

| 对比维度 | **Living-Dream-DSH**（本仓库） | Claude Code | GitHub Copilot | Cursor | OpenHands | Aider | Cline |
|---|---|---|---|---|---|---|---|
| **定位** | DSH 开源配置整合包：一键安装 + 8+ MCP + 插件 + 免费模型渠道 | Anthropic 官方 CLI/桌面 Agent | GitHub 官方 IDE 编程助手 | 商业化 AI IDE | 开源网页版 Agent（OpenDevin 后继） | 开源 git 原生 CLI Agent | 开源 VS Code Agent 插件 |
| **价格** | **¥0**（自带免费渠道，也可自备 Key） | Free / Pro $20/月 / Max 5x $100 / Max 20x $200 | Pro $10/月起，Business $19/席位 | Pro $20/月，Ultra $200/月 | 免费（BYOK，企业版另收费） | 免费（BYOK） | 免费（BYOK，企业版另收费） |
| **模型灵活性** | ✅ 多渠道 BYOK：DeepSeek、AMD Radeon（免费）、OpenCode Go、智谱视觉 | ❌ 仅 Claude 系列 | ⚠️ 绑定 GitHub 生态，多模型可选 | ⚠️ 多模型可选 | ✅ 任意 OpenAI 兼容模型 | ✅ 任意模型 | ✅ 任意模型 |
| **开箱即用工具（MCP）** | ✅ **8+ 个开箱即用**：桌面操作/浏览器/OCR/记忆/文档转换/代码执行/视觉/历史会话 | ⚠️ 原生支持 MCP，但需自行逐个配置 | ⚠️ MCP 支持有限 | ⚠️ 支持 MCP，需自行配置 | ⚠️ 支持 MCP，需自行配置 | ⚠️ 支持 MCP，需自行配置 | ⚠️ 支持 MCP，需自行配置 |
| **桌面自动化**（截图/点击/键鼠） | ✅ computer-use MCP | ⚠️ computer use（Beta） | ❌ | ❌ | ❌ | ❌ | ❌ |
| **浏览器控制** | ✅ Playwright MCP（真实登录态） | ⚠️ computer use（Beta） | ❌ | ❌ | ⚠️ 实验性 | ❌ | ⚠️ Browser Use（实验性） |
| **屏幕 OCR** | ✅ 离线 Windows OCR | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **文档转换**（PDF/Word/Excel→Markdown） | ✅ MarkItDown MCP | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **长期记忆** | ✅ 语义检索（本地向量库） | ✅ CLAUDE.md / 记忆文件 | ⚠️ 有限 | ⚠️ Rules 级别 | ⚠️ 会话级为主 | ❌ 依赖 git 历史 | ⚠️ 项目规则级 |
| **文件拖拽/粘贴上传** | ✅ 自研插件（拖拽 + Ctrl+V + 首次告知） | ⚠️ 部分支持 | ✅ IDE 原生 | ✅ IDE 原生 | ⚠️ 网页上传 | ❌ | ⚠️ 粘贴 |
| **手机远程访问** | ✅ Tailscale + 改写代理方案 | ✅ 官方 App / 网页版 | ❌ | ❌ | ✅ 网页端 | ❌ | ❌ |
| **中文生态** | ✅ **全中文文档 + 防坑指南 + 中文排障** | ❌ 官方英文为主 | ❌ | ❌ | ❌ | ❌ | ❌ |
| **开源 / 许可证** | ✅ MIT（含自研插件源码） | ❌ 闭源 | ❌ 闭源 | ❌ 闭源 | ✅ MIT | ✅ Apache-2.0 | ✅ Apache-2.0 |
| **数据隐私 / 自部署** | ✅ 本地优先，Key 自己持有 | ❌ 依赖 Anthropic 云端 | ❌ 依赖微软云端 | ❌ 依赖云端 | ✅ 可本地部署 | ✅ 纯本地 | ✅ 纯本地 |
| **安装成本** | ✅ 一键安装（环境检测/配置/密钥/快捷方式全自动） | ✅ 简单 | ✅ 简单 | ✅ 简单 | ⚠️ 需 Docker/环境 | ✅ 简单 | ✅ 简单 |
| **免费额度** | ✅ AMD Radeon 免费 + DeepSeek 注册赠金 + 智谱免费视觉 | ⚠️ Free 档有限用量 | ⚠️ 试用额度 | ⚠️ 试用额度 | ❌ 无（纯 BYOK） | ❌ 无（纯 BYOK） | ❌ 无（纯 BYOK） |

### 为什么选择 Living-Dream-DSH？

1. **成本：唯一「开箱即用且全免费」的方案。** Claude Code 重度使用每月 100~200 美元，Copilot/Cursor 也要 10~20 美元起。本仓库整合了多个免费模型渠道（AMD Radeon Cloud、DeepSeek 官方赠金、智谱 GLM-4V-Flash 免费视觉），把「能用」的门槛降到 0，同时保留 BYOK 能力——想用更好的模型随时切。

2. **能力：8+ MCP 开箱即用，别人要配半天。** 桌面自动化、浏览器控制、屏幕 OCR、文档转换、语义记忆、代码执行——其他框架要么不支持，要么支持但需要你逐个安装配置。本仓库一键装完即是全家桶，且每一项都是实战验证过的（踩坑记录都在防坑指南里）。

3. **中文生态：唯一全中文的一站式方案。** 完整中文文档、中文故障排查手册、中文防坑指南。商业产品和开源项目几乎都是英文文档为主，对中文用户的门槛是实打实的。

4. **开源 + 自研：真正的可掌控。** MIT 许可证，配置、脚本、自研插件源码全部公开，本地优先运行，API Key 自己持有不外泄。对比闭源的 Claude Code / Copilot / Cursor，没有供应商锁定；对比开源三件套（OpenHands/Aider/Cline），又多了「整合好的开箱配置」这一层。

5. **移动办公：手机远程操作桌面 Agent。** 基于 Tailscale 的远程方案，手机浏览器即可操控，这是多数 CLI/IDE 形态的竞品（Aider、Cline、Cursor）不具备的。

### 客观说明

- 免费渠道依赖第三方政策，稳定性和额度以渠道方为准；重度/商业使用建议 BYOK 或搭配商业订阅。
- 本仓库是 DeepSeek Harness 的配置整合包，不是独立 Agent 内核；「框架底座」的能力上限取决于 DSH 官方。
- 对比维度基于公开资料整理，部分功能（如 Claude Code computer use、Cline Browser Use）仍处 Beta，实际体验以官方为准。

### 适用场景速选

| 你的情况 | 推荐 |
|---|---|
| 想零成本体验全栈 Agent（写代码 + 操作桌面 + 控浏览器 + 远程） | **Living-Dream-DSH** |
| 愿意付费换最稳的模型质量，英文环境 OK | Claude Code |
| 重度使用 VS Code / GitHub 工作流 | GitHub Copilot |
| 想要图形化 IDE 的 AI 编程体验 | Cursor |
| 偏好纯开源、自己搭环境 | OpenHands / Aider / Cline |

---

## ✨ 特性一览

| 功能 | 说明 |
|------|------|
| 🔌 **8+ MCP 服务器** | 历史/视觉/桌面操作/代码执行/浏览器/记忆/文档转换/OCR |
| 🤖 **免费模型渠道** | AMD Radeon Cloud + DeepSeek 注册赠金 + 智谱免费视觉 |
| 📱 **手机远程访问** | Tailscale + 改写代理，手机浏览器操作 DSH |
| 🖼️ **发图自动识别** | GLM-4V-Flash 免费视觉描述（仅桌面版） |
| 📁 **文件拖拽上传** | 自研 dsh-file-uploads 插件 |
| 🔐 **密钥存储** | 明文 `.credentials.yaml`（DSH 读取）+ DPAPI 加密备份 `secrets.json`（`secrets.ps1` 解密）|
| 🛡️ **防坑指南** | 踩过的坑和解决方案全记录 |

---

## 📁 目录结构

```
Living-Dream-DSH/
├── README.md                    # 英文说明
├── README.zh.md                 # 中文说明
├── LICENSE                      # MIT 许可证
├── .gitignore
├── install.ps1                  # 一键安装脚本
├── install.bat                  # 安装包装器
├── package.json                 # 仓库脚本依赖（proxy.js 用的 http-proxy）
├── configs/
│   ├── cordis.patch.yml.template   # MCP 配置模板
│   ├── package.json.template       # 插件清单模板
│   ├── settings.yaml.template      # 全局设置模板
│   ├── AGENTS.md                   # AI 指令文件
│   ├── .credentials.yaml.template  # API Key 模板
│   └── README.md                   # 配置文件说明
├── scripts/
│   ├── start-dsh.bat.template      # DSH 启动器
│   ├── proxy.js                    # 手机远程代理（跨域改写）
│   ├── secrets.ps1                 # DPAPI 密钥解密（读取 secrets.json）
│   ├── os-copilot-mcp-server.py    # OS-Copilot MCP（旧位置）
│   ├── os-copilot-mcp-README.md    # OS-Copilot MCP 说明
│   ├── os-copilot-mcp-LICENSE      # OS-Copilot MIT 许可证
│   └── mcp/                        # MCP 服务端脚本（6 个全部内置）
│       ├── dsh-history-server.py
│       ├── dsh-vision-server.py
│       ├── dsh-memory-server.py
│       ├── store_engine.py         # 记忆引擎（SQLite + 向量检索）
│       ├── dsh-markitdown-server.py
│       ├── dsh-ocr-server.py
│       └── os-copilot-server.py
├── plugins/
│   ├── README.md                   # 插件安装说明
│   └── dsh-paste-input/            # 自研文件拖拽上传插件
│       ├── package.json
│       ├── lib/
│       │   ├── index.js
│       │   └── client.js
│       ├── cordis.patch.yml
│       ├── README.md
│       └── LICENSE
└── docs/
    ├── comparison.md               # 英文对比表（7 框架）
    ├── comparison.zh.md            # 中文对比表
    ├── phone-remote.md             # 手机远程访问教程
    ├── vision-patch.md             # 发图自动识别补丁
    └── troubleshooting.md          # 防坑指南
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

> 💡 安装 Python 后执行 `pip install mcp markitdown zstandard`，MCP 服务器才能正常启动。
> 一键安装脚本会自动完成此步骤。

> 💡 启动器会自动探测 DSH 桌面版安装路径。如果探测失败，请设置：
> `$env:DSH_DESKTOP_PATH = "D:\Tools\DeepSeekHarness-Desktop"`（改为你的实际路径），
> 或添加到系统环境变量永久生效。

### 方式一：离线安装 ⭐ 推荐

> **安装过程无需联网。** Node.js、Python、Git 已打包在内。

1. 从 Releases 下载 [`Living-Dream-DSH-v1.2.0-Offline.exe`](https://github.com/alllllllllli/Living-Dream-DSH/releases/download/v1.2.0/Living-Dream-DSH-v1.2.0-Offline.exe)（约 120 MB）
2. 双击运行 — 自动解压依赖 + 仓库 + 安装脚本到临时目录
3. PowerShell 安装程序自动启动：
   - 从本地文件安装 Node.js、Python、Git（不下载）
   - 复制配置文件到 `~/.dsh`
   - 交互式填入 API Key
   - 安装插件依赖
   - 创建桌面快捷方式

```
Living-Dream-DSH-v1.2.0-Offline.exe（SFX 内容，不在仓库中）
├── deps/                      # Node.js 22.16.0 MSI, Python 3.13.0, Git 2.47.0
├── Living-Dream-DSH/          # 完整仓库快照
└── install-offline.ps1        # 离线安装脚本（打包在内，不在仓库中）
```

### 方式二：在线一键安装

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

### 方式三：手动安装

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

# 5. 安装插件（dsh-paste-input 是 file: 依赖, 仓库已内置源码）
Copy-Item plugins\dsh-paste-input $env:USERPROFILE\.dsh\profiles\plugins\dsh-paste-input -Recurse
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install

# 6. 重启 DSH 桌面版
```

</details>

---

## 🔌 MCP 服务器列表

> 所有服务端脚本已内置在 `scripts/mcp/` 目录。一键安装自动配置路径。

| MCP | 功能 | 脚本 | 额外依赖 |
|-----|------|------|----------|
| `dsh-history` | 历史会话搜索 | `scripts/mcp/dsh-history-server.py` | `pip install mcp zstandard` |
| `dsh-vision` | 图片分析（Ollama） | `scripts/mcp/dsh-vision-server.py` | Ollama + qwen2.5vl 模型 |
| `dsh-computer` | 桌面操作 | —（npx） | `@zavora-ai/computer-use-mcp`（自动安装） |
| `os-copilot` | 代码执行 | `scripts/mcp/os-copilot-server.py` | `pip install mcp` |
| `dsh-browser` | 浏览器自动化 | —（npx） | `@playwright/mcp`（自动安装） |
| `dsh-memory` | 长期记忆 | `scripts/mcp/dsh-memory-server.py` | 内嵌 store_engine + Ollama bge-m3 |
| `dsh-markitdown` | 文档转 Markdown | `scripts/mcp/dsh-markitdown-server.py` | `pip install mcp markitdown` |
| `dsh-ocr` | 屏幕 OCR（Windows） | `scripts/mcp/dsh-ocr-server.py` | `pip install mcp`，Windows 10+ |

---

## 🤖 免费模型渠道

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
npm install http-proxy                  # 首次需安装依赖
node scripts/proxy.js                   # 监听 127.0.0.1:8090

# 4. 配置 serve（指向 8090 代理，不是 3080）
tailscale serve --https=443 --bg http://127.0.0.1:8090

# 5. 手机浏览器访问
# https://<你的设备名>.<你的域名>.ts.net
```

详见 [docs/phone-remote.md](docs/phone-remote.md)

---

## 🖼️ 发图自动识别改造

让 DSH 桌面版发图时自动调用 GLM-4V-Flash 识别：

```powershell
# 1. 备份原文件
$dshPath = (Get-Process DeepSeekHarness* -ErrorAction SilentlyContinue).Path
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
- [智谱 AI](https://open.bigmodel.cn/) - GLM-4V-Flash 视觉模型

---

**最后更新**：2026-08-17
