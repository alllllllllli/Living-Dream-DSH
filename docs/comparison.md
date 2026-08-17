# Living-Dream-DSH vs. Mainstream AI Coding Frameworks

> Data as of 2026-08. Prices from official pages. Living-Dream-DSH is an open-source DSH config pack (MIT).

## Overview

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

## Why Choose Living-Dream-DSH?

1. **Zero cost**: The only "out-of-box and fully free" option. Claude Code costs $100–200/mo for heavy use; Copilot/Cursor start at $10–20/mo. This repo integrates multiple free model channels (AMD Radeon Cloud, DeepSeek signup bonus, Zhipu GLM-4V-Flash free vision), lowering the barrier to $0 while keeping BYOK for upgrades.

2. **Full-stack capability**: 8+ MCP servers out of the box — desktop automation, browser control, screen OCR, doc conversion, semantic memory, code execution. Others either don't support these or require manual per-server setup. One install = full toolkit, every component battle-tested (pitfalls documented in the troubleshooting guide).

3. **Chinese ecosystem**: The only full-Chinese one-stop solution. Complete Chinese docs, troubleshooting manual, and anti-pitfall guide. Commercial products and OSS projects are predominantly English, which is a real barrier for Chinese users.

4. **Open source + self-built**: MIT license — configs, scripts, custom plugin source all public. Local-first, API keys stay with you. No vendor lock-in vs. closed-source Claude Code/Copilot/Cursor; vs. OSS trio (OpenHands/Aider/Cline), adds the "pre-integrated config" layer.

5. **Mobile office**: Tailscale-based remote access from phone browser — a capability most CLI/IDE competitors (Aider, Cline, Cursor) lack.

## Caveats

- Free channels depend on third-party policies; stability and quotas are subject to change. Heavy/commercial use recommended with BYOK or commercial subscriptions.
- This repo is a DSH config pack, not an independent agent kernel; the "framework ceiling" depends on official DSH capabilities.
- Comparison based on public info; some features (Claude Code computer use, Cline Browser Use) are still in Beta.

## Quick Decision Guide

| Your situation | Recommendation |
|---|---|
| Zero-cost full-stack agent (code + desktop + browser + remote) | **Living-Dream-DSH** |
| Willing to pay for best model quality, OK with English | Claude Code |
| Heavy VS Code / GitHub workflow | GitHub Copilot |
| Want a graphical AI IDE | Cursor |
| Prefer pure OSS, DIY environment | OpenHands / Aider / Cline |
