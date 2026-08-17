# Living-Dream-DSH vs 主流 AI 编程框架对比

> 数据截至 2026-08，价格以各官方页面为准。Living-Dream-DSH 为基于 DeepSeek Harness 的开源配置整合包（MIT 许可证）。

## 总览对比表

| 对比维度 | **Living-Dream-DSH**（本仓库） | Claude Code | GitHub Copilot | Cursor | OpenHands | Aider | Cline |
|---|---|---|---|---|---|---|---|
| **定位** | DSH 开源配置整合包：一键安装 + 8+ MCP + 插件 + 免费模型渠道 | Anthropic 官方 CLI/桌面 Agent | GitHub 官方 IDE 编程助手 | 商业化 AI IDE | 开源网页版 Agent（OpenDevin 后继） | 开源 git 原生 CLI Agent | 开源 VS Code Agent 插件 |
| **价格** | **¥0**（自带免费渠道，也可自备 Key） | Free / Pro $20/月 / Max 5x $100 / Max 20x $200 | Pro $10/月起，Business $19/席位 | Pro $20/月，Ultra $200/月 | 免费（BYOK，企业版另收费） | 免费（BYOK） | 免费（BYOK，企业版另收费） |
| **模型灵活性** | ✅ 多渠道 BYOK：DeepSeek、CNB（免费）、AMD Radeon（免费）、OpenCode Go、智谱视觉 | ❌ 仅 Claude 系列 | ⚠️ 绑定 GitHub 生态，多模型可选 | ⚠️ 多模型可选 | ✅ 任意 OpenAI 兼容模型 | ✅ 任意模型 | ✅ 任意模型 |
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
| **免费额度** | ✅ CNB 500 积分/月 + AMD Radeon 免费 + DeepSeek 注册赠金 + 智谱免费视觉 | ⚠️ Free 档有限用量 | ⚠️ 试用额度 | ⚠️ 试用额度 | ❌ 无（纯 BYOK） | ❌ 无（纯 BYOK） | ❌ 无（纯 BYOK） |

## 为什么选择 Living-Dream-DSH？

1. **成本：唯一「开箱即用且全免费」的方案。** Claude Code 重度使用每月 100~200 美元，Copilot/Cursor 也要 10~20 美元起。本仓库整合了多个免费模型渠道（CNB、AMD Radeon Cloud、DeepSeek 官方赠金、智谱 GLM-4V-Flash 免费视觉），把「能用」的门槛降到 0，同时保留 BYOK 能力——想用更好的模型随时切。

2. **能力：8+ MCP 开箱即用，别人要配半天。** 桌面自动化、浏览器控制、屏幕 OCR、文档转换、语义记忆、代码执行——其他框架要么不支持，要么支持但需要你逐个安装配置。本仓库一键装完即是全家桶，且每一项都是实战验证过的（踩坑记录都在防坑指南里）。

3. **中文生态：唯一全中文的一站式方案。** 完整中文文档、中文故障排查手册、中文防坑指南。商业产品和开源项目几乎都是英文文档为主，对中文用户的门槛是实打实的。

4. **开源 + 自研：真正的可掌控。** MIT 许可证，配置、脚本、自研插件源码全部公开，本地优先运行，API Key 自己持有不外泄。对比闭源的 Claude Code / Copilot / Cursor，没有供应商锁定；对比开源三件套（OpenHands/Aider/Cline），又多了「整合好的开箱配置」这一层。

5. **移动办公：手机远程操作桌面 Agent。** 基于 Tailscale 的远程方案，手机浏览器即可操控，这是多数 CLI/IDE 形态的竞品（Aider、Cline、Cursor）不具备的。

## 客观说明

- 免费渠道依赖第三方政策，稳定性和额度以渠道方为准；重度/商业使用建议 BYOK 或搭配商业订阅。
- 本仓库是 DeepSeek Harness 的配置整合包，不是独立 Agent 内核；「框架底座」的能力上限取决于 DSH 官方。
- 对比维度基于公开资料整理，部分功能（如 Claude Code computer use、Cline Browser Use）仍处 Beta，实际体验以官方为准。

## 适用场景速选

| 你的情况 | 推荐 |
|---|---|
| 想零成本体验全栈 Agent（写代码 + 操作桌面 + 控浏览器 + 远程） | **Living-Dream-DSH** |
| 愿意付费换最稳的模型质量，英文环境 OK | Claude Code |
| 重度使用 VS Code / GitHub 工作流 | GitHub Copilot |
| 想要图形化 IDE 的 AI 编程体验 | Cursor |
| 偏好纯开源、自己搭环境 | OpenHands / Aider / Cline |
