# Living Dream DSH 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-config-4f46e5)](https://github.com/deepseek-ai/deepseek-harness)

**Living Dream DSH — The Ultimate DeepSeek Harness Desktop Configuration**

A battle-tested DSH configuration framework with 8+ MCP servers, custom plugins, free model access, mobile remote control, and more.

> 📖 [English](README.md) | [简体中文](README.zh.md)

---

## 🆚 Living Dream DSH vs Claude Code

| Feature | Living Dream DSH | Claude Code |
|---------|------------------|-------------|
| **Model** | DeepSeek V4 (Free) | Claude (Paid) |
| **Free Tier** | ✅ CNB Proxy, AMD Radeon Cloud | ❌ Paid only |
| **MCP Servers** | ✅ 8+ (Desktop/Browser/OCR/Memory) | ❌ None |
| **Desktop Automation** | ✅ Screenshot/Click/Keyboard | ❌ None |
| **Browser Control** | ✅ Playwright automation | ❌ None |
| **Mobile Access** | ✅ Tailscale solution | ❌ None |
| **Image Recognition** | ✅ GLM-4V-Flash (Free) | ❌ Extra cost |
| **File Drag & Drop** | ✅ Custom plugin | ❌ None |
| **Long-term Memory** | ✅ Semantic search | ❌ None |
| **Document Conversion** | ✅ MarkItDown | ❌ None |
| **Screen OCR** | ✅ Windows OCR | ❌ None |
| **Open Source** | ✅ MIT License | ❌ Closed source |
| **Pricing** | 🆓 Free | 💰 $20/month+ |

**Why choose Living Dream DSH?**

1. **Zero cost**: Use DeepSeek V4 completely free via CNB Proxy and AMD Radeon Cloud
2. **Full-stack capability**: Not just coding — control desktop, browser, recognize images
3. **Mobile office**: Access from phone browser anytime, anywhere
4. **Open source**: MIT license, freely modifiable and extensible

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔌 **8+ MCP Servers** | History/Vision/Desktop/Code Execution/Browser/Memory/Document/OCR |
| 🤖 **Free Model Access** | CNB Proxy (DeepSeek V4 Free) + AMD Radeon Cloud |
| 📱 **Mobile Remote Access** | Tailscale + Proxy, control DSH from phone |
| 🖼️ **Auto Image Recognition** | GLM-4V-Flash free vision (Desktop only) |
| 📁 **File Drag & Drop** | Custom dsh-file-uploads plugin |
| 🔐 **Secure Key Storage** | DPAPI encryption + secrets.ps1 |
| 🛡️ **Troubleshooting Guide** | All pitfalls and solutions documented |

---

## 📁 Directory Structure

```
Living-Dream-DSH/
├── README.md                    # English
├── README.zh.md                 # Chinese
├── LICENSE                      # MIT License
├── .gitignore
├── configs/
│   ├── cordis.patch.yml.template   # MCP config template
│   ├── package.json.template       # Plugin list template
│   ├── settings.yaml.template      # Global settings template
│   ├── AGENTS.md                   # AI instructions
│   └── .credentials.yaml.template  # API Key template
├── scripts/
│   ├── cnb_proxy.py                # CNB Proxy (OpenAI compatible)
│   ├── secrets.ps1                 # DPAPI key decryption
│   ├── start-dsh.bat.template      # Launcher template
│   ├── os-copilot-mcp-server.py    # OS-Copilot MCP server
│   └── os-copilot-mcp-README.md    # OS-Copilot MCP docs
├── plugins/
│   └── README.md                   # Plugin installation guide
└── docs/
    ├── phone-remote.md             # Mobile remote access tutorial
    ├── vision-patch.md             # Image recognition patch
    └── troubleshooting.md          # Troubleshooting manual
```

---

## 🚀 Quick Start

### Option 1: One-Click Install (Recommended)

```powershell
# 1. Clone repository
git clone https://github.com/alllllllllli/Living-Dream-DSH.git
cd Living-Dream-DSH

# 2. Double-click install.bat
#    Or run in PowerShell: .\install.ps1
```

The installer will automatically:
- ✅ Check environment (Node.js, Python, pnpm)
- ✅ Copy config files to `~/.dsh`
- ✅ Interactively fill in API Keys
- ✅ Install plugin dependencies
- ✅ Create desktop shortcut

### Option 2: Manual Install

<details>
<summary>Click to expand manual installation steps</summary>

#### Requirements

- Windows 10/11
- Node.js v22+ (Recommended v24 LTS)
- Python 3.13+ (For MCP servers)
- DeepSeek Harness Desktop v1.1.0+

#### Installation Steps

```powershell
# Clone repository
git clone https://github.com/alllllllllli/Living-Dream-DSH.git
cd Living-Dream-DSH

# Copy config files to DSH directory
Copy-Item configs\cordis.patch.yml.template $env:USERPROFILE\.dsh\profiles\web\cordis.patch.yml
Copy-Item configs\package.json.template $env:USERPROFILE\.dsh\profiles\web\package.json
Copy-Item configs\settings.yaml.template $env:USERPROFILE\.dsh\settings.yaml
Copy-Item configs\AGENTS.md $env:USERPROFILE\.dsh\AGENTS.md

# Edit config files (fill in your API Keys)
notepad $env:USERPROFILE\.dsh\.credentials.yaml

# Install plugins
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install

# Restart DSH Desktop
```

</details>

### 3. Configure MCP Servers

See [configs/README.md](configs/README.md)

---

## 🔌 MCP Server List

| MCP | Function | Dependencies |
|-----|----------|--------------|
| `dsh-history` | History session query/search | Python + server.py |
| `dsh-vision` | Image analysis (Ollama qwen2.5vl) | Python + Ollama |
| `dsh-computer` | Desktop automation (screenshot/click/keyboard) | @zavora-ai/computer-use-mcp (MIT) |
| `os-copilot` | Code execution (Python/Shell/File ops) | Python + server.py |
| `dsh-browser` | Browser automation (Playwright) | Node.js + Edge extension |
| `dsh-memory` | Long-term memory (semantic search) | Python + server.py |
| `dsh-markitdown` | Document to Markdown | Python + MarkItDown |
| `dsh-ocr` | Screen OCR | Python + Windows OCR |

---

## 🤖 Free Model Access

### CNB Proxy (Recommended)

```powershell
# Start CNB Proxy
python scripts\cnb_proxy.py --port 8800

# Or use launcher (auto-detect and start)
scripts\start-dsh.bat
```

**Supported Models:**
- `deepseek-v4-flash` - Free until 2026-12-31
- `deepseek-v4-pro` - 500 free credits per month

### AMD Radeon Cloud

- Endpoint: `https://developer.amd.com.cn/radeon/api/v1`
- Model: DeepSeek-V4-Flash
- Register: developer.amd.com.cn/radeon

---

## 📱 Mobile Remote Access

Access DSH from phone browser via Tailscale:

```powershell
# 1. Install Tailscale
winget install tailscale.tailscale

# 2. Login to same account
tailscale up

# 3. Configure serve
tailscale serve --https=443 --bg http://127.0.0.1:3080

# 4. Access from phone browser
# https://<your-device-name>.<your-domain>.ts.net
```

See [docs/phone-remote.md](docs/phone-remote.md)

---

## 🖼️ Image Recognition Patch

Make DSH Desktop auto-call GLM-4V-Flash for image recognition:

```powershell
# 1. Backup original file
Copy-Item "D:\ToolsDeepSeek-Harness-Desktop\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" `
          "G:\vision-files\dsh-host-apiproxy-index.js.bak"

# 2. Apply patch (manually modify describeImagesLocally function around line 911)
# See docs/vision-patch.md
```

⚠️ **Note**: DSH upgrades will overwrite this patch, re-apply after upgrade.

---

## 🛡️ Troubleshooting

### 1. Plugin Installation

```powershell
# ✅ Correct way
dsh plugin --profile web add <package>@<version>

# ❌ Wrong way (will clear unlisted bundles)
cd $env:USERPROFILE\.dsh\profiles\web
pnpm add <package>
```

### 2. Desktop vs Dev Version Conflict

Both share `~/.dsh`, causing concurrent write conflicts. Close Dev version (port 3080) when using Desktop.

### 3. Image Patch

DSH upgrades will overwrite `dsh-host-apiproxy` modifications, re-apply patch.

### 4. billion-context-dsh Version

Must lock version `0.2.1`, default will misparse as `0.1.7` (no dsh.bundle).

---

## 📝 Configuration Files

### cordis.patch.yml

MCP server config file at `~/.dsh/profiles/web/cordis.patch.yml`

```yaml
# Example: Add an MCP server
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

Global settings file at `~/.dsh/settings.yaml`

```yaml
# Configure model providers
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

API Key storage at `~/.dsh/.credentials.yaml`

```yaml
MY_API_KEY: sk-xxxxxxxxxxxx
```

---

## 🔧 Custom Extensions

### Add New MCP Server

1. Create MCP server (reference existing implementations)
2. Add config to `cordis.patch.yml`
3. Add plugin to `package.json` bundles (if needed)
4. Restart DSH Desktop

### Create Custom Plugin

Reference [dsh-file-uploads](https://github.com/l541402398/dsh-file-uploads) plugin structure.

---

## 📚 Resources

- [DeepSeek Harness Official](https://github.com/deepseek-ai/deepseek-harness)
- [DSH Handbook](https://github.com/Electricitysheep/dsh-handbook)
- [Playwright MCP](https://github.com/anthropics/anthropic-quickstarts/tree/main/computer-use-demo)
- [MarkItDown](https://github.com/microsoft/markitdown)

---

## 🤝 Contributing

Issues and Pull Requests are welcome!

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- [DeepSeek](https://www.deepseek.com/) - DSH Framework
- [l541402398](https://github.com/l541402398) - dsh-file-uploads plugin author
- [CNB](https://cnb.cool/) - Free API access
- [Zhipu AI](https://open.bigmodel.cn/) - GLM-4V-Flash vision model

---

**Last Updated**: 2026-08-17
