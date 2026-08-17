# Living Dream DSH 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![DeepSeek Harness](https://img.shields.io/badge/DeepSeek%20Harness-config-4f46e5)](https://github.com/deepseek-ai/deepseek-harness)

**Living Dream DSH — The Ultimate DeepSeek Harness Desktop Configuration**

A battle-tested DSH configuration framework with 8+ MCP servers, custom plugins, free model access, mobile remote control, and more.

> 📖 [English](README.md) | [简体中文](README.zh.md)

---

## 🆚 Living Dream DSH vs. Mainstream AI Coding Frameworks

> Data as of 2026-08. Prices from official pages. Living-Dream-DSH is an open-source DSH config pack (MIT).

### Overview

| Dimension | **Living-Dream-DSH** (this repo) | Claude Code | GitHub Copilot | Cursor | OpenHands | Aider | Cline |
|---|---|---|---|---|---|---|---|
| **Positioning** | DSH open-source config pack: one-click install + 8+ MCP + plugins + free model channels | Anthropic official CLI/desktop agent | GitHub official IDE assistant | Commercial AI IDE | Open-source web agent (OpenDevin successor) | Open-source git-native CLI agent | Open-source VS Code agent plugin |
| **Price** | **$0** (built-in free channels, or BYOK) | Free / Pro $20/mo / Max 5x $100 / Max 20x $200 | Pro $10/mo+, Business $19/seat | Pro $20/mo, Ultra $200/mo | Free (BYOK, enterprise extra) | Free (BYOK) | Free (BYOK, enterprise extra) |
| **Model flexibility** | ✅ Multi-channel BYOK: DeepSeek, AMD Radeon (free), OpenCode Go, Zhipu Vision | ❌ Claude only | ⚠️ GitHub ecosystem bound | ⚠️ Multiple models | ✅ Any OpenAI-compatible | ✅ Any model | ✅ Any model |
| **MCP servers (out-of-box)** | ✅ **8+ ready to use**: desktop/browser/OCR/memory/doc conversion/code exec/vision/history | ⚠️ Native MCP, self-configure each | ⚠️ Limited MCP | ⚠️ MCP, self-configure | ⚠️ MCP, self-configure | ⚠️ MCP, self-configure | ⚠️ MCP, self-configure |
| **Desktop automation** (screenshot/click/keyboard) | ✅ computer-use MCP | ⚠️ computer use (Beta) | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Browser control** | ✅ Playwright MCP (real login state) | ⚠️ computer use (Beta) | ❌ | ❌ | ⚠️ Experimental | ❌ | ⚠️ Browser Use (experimental) |
| **Screen OCR** | ✅ Offline Windows OCR | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Doc conversion** (PDF/Word/Excel → Markdown) | ✅ MarkItDown MCP | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Long-term memory** | ✅ Semantic search (local vector store) | ✅ CLAUDE.md / memory files | ⚠️ Limited | ⚠️ Rules level | ⚠️ Session-level | ❌ Git history only | ⚠️ Project rules |
| **File drag & paste upload** | ✅ Custom plugin (drag + Ctrl+V + first-time guide) | ⚠️ Partial | ✅ IDE native | ✅ IDE native | ⚠️ Web upload | ❌ | ⚠️ Paste |
| **Mobile remote access** | ✅ Tailscale + proxy rewrite | ✅ Official app / web | ❌ | ❌ | ✅ Web UI | ❌ | ❌ |
| **Chinese ecosystem** | ✅ **Full Chinese docs + troubleshooting + anti-pitfall guide** | ❌ English only | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Open source / License** | ✅ MIT (incl. custom plugins) | ❌ Closed | ❌ Closed | ❌ Closed | ✅ MIT | ✅ Apache-2.0 | ✅ Apache-2.0 |
| **Data privacy / self-host** | ✅ Local-first, your keys | ❌ Anthropic cloud | ❌ Microsoft cloud | ❌ Cloud | ✅ Self-hostable | ✅ Fully local | ✅ Fully local |
| **Install effort** | ✅ One-click (env detect/config/keys/shortcut auto) | ✅ Easy | ✅ Easy | ✅ Easy | ⚠️ Docker/env needed | ✅ Easy | ✅ Easy |
| **Free quota** | ✅ AMD Radeon free + DeepSeek signup bonus + Zhipu free vision | ⚠️ Free tier limited | ⚠️ Trial quota | ⚠️ Trial quota | ❌ BYOK only | ❌ BYOK only | ❌ BYOK only |

### Why Choose Living-Dream-DSH?

1. **Zero cost**: The only "out-of-box and fully free" option. Claude Code costs $100–200/mo for heavy use; Copilot/Cursor start at $10–20/mo. This repo integrates multiple free model channels (AMD Radeon Cloud, DeepSeek signup bonus, Zhipu GLM-4V-Flash free vision), lowering the barrier to $0 while keeping BYOK for upgrades.

2. **Full-stack capability**: 8+ MCP servers out of the box — desktop automation, browser control, screen OCR, doc conversion, semantic memory, code execution. Others either don't support these or require manual per-server setup. One install = full toolkit, every component battle-tested (pitfalls documented in the troubleshooting guide).

3. **Chinese ecosystem**: The only full-Chinese one-stop solution. Complete Chinese docs, troubleshooting manual, and anti-pitfall guide. Commercial products and OSS projects are predominantly English, which is a real barrier for Chinese users.

4. **Open source + self-built**: MIT license — configs, scripts, custom plugin source all public. Local-first, API keys stay with you. No vendor lock-in vs. closed-source Claude Code/Copilot/Cursor; vs. OSS trio (OpenHands/Aider/Cline), adds the "pre-integrated config" layer.

5. **Mobile office**: Tailscale-based remote access from phone browser — a capability most CLI/IDE competitors (Aider, Cline, Cursor) lack.

### Caveats

- Free channels depend on third-party policies; stability and quotas are subject to change. Heavy/commercial use recommended with BYOK or commercial subscriptions.
- This repo is a DSH config pack, not an independent agent kernel; the "framework ceiling" depends on official DSH capabilities.
- Comparison based on public info; some features (Claude Code computer use, Cline Browser Use) are still in Beta.

### Quick Decision Guide

| Your situation | Recommendation |
|---|---|
| Zero-cost full-stack agent (code + desktop + browser + remote) | **Living-Dream-DSH** |
| Willing to pay for best model quality, OK with English | Claude Code |
| Heavy VS Code / GitHub workflow | GitHub Copilot |
| Want a graphical AI IDE | Cursor |
| Prefer pure OSS, DIY environment | OpenHands / Aider / Cline |

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔌 **8+ MCP Servers** | History/Vision/Desktop/Code Execution/Browser/Memory/Document/OCR |
| 🤖 **Free Model Access** | AMD Radeon Cloud + DeepSeek Signup Bonus + Zhipu Free Vision |
| 📱 **Mobile Remote Access** | Tailscale + Proxy, control DSH from phone |
| 🖼️ **Auto Image Recognition** | GLM-4V-Flash free vision (Desktop only) |
| 📁 **File Drag & Drop** | Custom dsh-file-uploads plugin |
| 🔐 **Secure Key Storage** | DPAPI-encrypted backup (`secrets.json` + `secrets.ps1`) alongside plaintext `.credentials.yaml` |
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
│   ├── start-dsh.bat.template       # DSH launcher
│   ├── proxy.js                     # Phone remote proxy (CORS rewrite)
│   ├── secrets.ps1                  # DPAPI key decryption (reads secrets.json)
│   ├── mcp/                         # MCP server scripts (all 6 bundled)
│   │   ├── dsh-history-server.py
│   │   ├── dsh-vision-server.py
│   │   ├── dsh-memory-server.py
│   │   ├── dsh-markitdown-server.py
│   │   ├── dsh-ocr-server.py
│   │   └── os-copilot-server.py
│   └── os-copilot-mcp-README.md     # OS-Copilot MCP docs
├── plugins/
│   └── README.md                   # Plugin installation guide
└── docs/
    ├── phone-remote.md             # Mobile remote access tutorial
    ├── vision-patch.md             # Image recognition patch
    └── troubleshooting.md          # Troubleshooting manual
```

---

## 🚀 Quick Start

### Prerequisites (Must Install First)

| Software | Version | Download | Required |
|----------|---------|----------|----------|
| **DeepSeek Harness Desktop** | v1.1.0+ | [GitHub Releases](https://github.com/deepseek-ai/deepseek-harness/releases) | ✅ Yes |
| **Node.js** | v22+ (Recommended v24 LTS) | [nodejs.org](https://nodejs.org/) | ✅ Yes |
| **Python** | 3.13+ | [python.org](https://python.org/) | ✅ Yes |
| **pnpm** | Latest | `npm install -g pnpm` | ✅ Yes |
| **Git** | Any | [git-scm.com](https://git-scm.com/) | For clone |

> 💡 After installing Python, run `pip install mcp markitdown` to enable all MCP servers.
> The one-click installer does this automatically.

> 💡 Some scripts reference `$env:DSH_DESKTOP_PATH` — set it to your DSH Desktop install directory:
> `$env:DSH_DESKTOP_PATH = "D:\Tools\DeepSeek-Harness-Desktop"` (change to your actual path),
> or add it as a system environment variable for persistence.

### Option 1: Offline Install ⭐ Recommended

> **No internet required during install.** Node.js, Python, Git are bundled in the package.

1. Download [`Living-Dream-DSH-Offline.exe`](https://github.com/alllllllllli/Living-Dream-DSH/releases/download/v1.1.1/Living-Dream-DSH-Offline.exe) (~120 MB) from Releases
2. Double-click to run — it extracts deps + repo + installer to a temp directory
3. The PowerShell installer launches automatically:
   - Installs Node.js, Python, Git from local files (no download)
   - Copies configs to `~/.dsh`
   - Prompts for API Keys
   - Installs plugin dependencies
   - Creates desktop shortcut

```
Living-Dream-DSH-Offline.exe
├── deps/                      # Node.js 22.16.0 MSI, Python 3.13.0, Git 2.47.0
├── Living-Dream-DSH/          # Full repo snapshot
└── install-offline.ps1        # Offline installer script
```

### Option 2: Online One-Click Install

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

### Option 3: Manual Install

<details>
<summary>Click to expand manual installation steps</summary>

#### Step-by-Step

```powershell
# 1. Install prerequisites (if not installed)
winget install OpenJS.NodeJS.LTS        # Node.js
winget install Python.Python.3.13       # Python
npm install -g pnpm                      # pnpm

# 2. Clone repository
git clone https://github.com/alllllllllli/Living-Dream-DSH.git
cd Living-Dream-DSH

# 3. Copy config files to DSH directory
Copy-Item configs\cordis.patch.yml.template $env:USERPROFILE\.dsh\profiles\web\cordis.patch.yml
Copy-Item configs\package.json.template $env:USERPROFILE\.dsh\profiles\web\package.json
Copy-Item configs\settings.yaml.template $env:USERPROFILE\.dsh\settings.yaml
Copy-Item configs\AGENTS.md $env:USERPROFILE\.dsh\AGENTS.md
Copy-Item configs\.credentials.yaml.template $env:USERPROFILE\.dsh\.credentials.yaml

# 4. Edit config files (fill in your API Keys)
notepad $env:USERPROFILE\.dsh\.credentials.yaml

# 5. Install plugins (dsh-paste-input is a file: dependency - bundled in repo)
Copy-Item plugins\dsh-paste-input $env:USERPROFILE\.dsh\profiles\plugins\dsh-paste-input -Recurse
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install

# 6. Restart DSH Desktop
```

</details>

### 4. Configure MCP Servers

See [configs/README.md](configs/README.md)

---

## 🔌 MCP Server List

> All server scripts are bundled in `scripts/mcp/`. One-click installer configures paths automatically.

| MCP | Function | Script | Extra Dependencies |
|-----|----------|--------|--------------------|
| `dsh-history` | Session history search | `scripts/mcp/dsh-history-server.py` | `pip install mcp` |
| `dsh-vision` | Image analysis (Ollama) | `scripts/mcp/dsh-vision-server.py` | Ollama + qwen2.5vl model |
| `dsh-computer` | Desktop automation | — (npx) | `@zavora-ai/computer-use-mcp` (auto-installed) |
| `os-copilot` | Code execution | `scripts/mcp/os-copilot-server.py` | `pip install mcp` |
| `dsh-browser` | Browser automation | — (npx) | `@playwright/mcp` (auto-installed) |
| `dsh-memory` | Long-term memory | `scripts/mcp/dsh-memory-server.py` | `pip install mcp` |
| `dsh-markitdown` | Document → Markdown | `scripts/mcp/dsh-markitdown-server.py` | `pip install mcp markitdown` |
| `dsh-ocr` | Screen OCR (Windows) | `scripts/mcp/dsh-ocr-server.py` | `pip install mcp`, Windows 10+ |

---

## 🤖 Free Model Access

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

# 3. Start the rewrite proxy (must go through 8090 - DSH Web UI has CORS
#    checks, connecting directly to 3080 fails)
npm install http-proxy                  # one-time dependency
node scripts/proxy.js                   # listens on 127.0.0.1:8090

# 4. Configure serve (point to the 8090 proxy, NOT 3080)
tailscale serve --https=443 --bg http://127.0.0.1:8090

# 5. Access from phone browser
# https://<your-device-name>.<your-domain>.ts.net
```

See [docs/phone-remote.md](docs/phone-remote.md)

---

## 🖼️ Image Recognition Patch

Make DSH Desktop auto-call GLM-4V-Flash for image recognition:

```powershell
# 1. Backup original file
$dshPath = (Get-Process "DeepSeek Harness" -ErrorAction SilentlyContinue).Path
if (-not $dshPath) { $dshPath = "D:\Tools\DeepSeek-Harness-Desktop" }
Copy-Item "$dshPath\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js" `
          "$env:USERPROFILE\dsh-host-apiproxy-index.js.bak"

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
- [Playwright MCP](https://github.com/microsoft/playwright-mcp)
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
- [Zhipu AI](https://open.bigmodel.cn/) - GLM-4V-Flash vision model

---

**Last Updated**: 2026-08-17
