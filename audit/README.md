# DSH 全架构审计与修复归档

本目录归档对 DeepSeek Harness (DSH，231 个 `@deepseek-ai` 包、约 24 万行编译 JS) 的一次系统性 bug 审计与高价值修复。

## 内容

- `final-report.md` — 最终分级报告：1 高危 / 5 中危 / 19 低危 / 2 latent / 13+ 排除项，含每条的根因 / 证据 / 修复方案 + 架构小结。
- `findings-ledger.md` — 两轮审计（第一轮 9 子代理 + 第二轮 AgentTeams 对抗性复核）的 findings 权威台账。
- `fix-ledger.md` — 20 项已应用修复 + 5 项明确 defer 的理由 + 全量终验结果。
- `patches/` — 16 个修复的 unified diff（**只含改动，不含 DeepSeek 原始源码**）。
- `fix-checks/` — 4 个 runnable check（ssrf / llm-id / terminal-lines / sanitizer）。

## 修复清单（详见 `fix-ledger.md`）

| 级别 | 项 |
|---|---|
| 高危 | SSRF — `web_fetch` 可让宿主 fetch 任意内网/云元数据 |
| 中危 | `PRIVILEGED_METHODS` 漏 `host.listDirectory`/`createDirectory`；LLM tool-call id 兜底死代码；pi-ai 非 LlmError 不重试；file-uploads `clearInFlight` 过早 |
| 低危 ×15 | pwsh parity / blocks() / llm-retry / cordis-host-runner 优先级 / subprocess×2 / file-uploads×3 / paste-input×2 / atomic-write fsync / terminal-bash off-by-one / session-stats turns |

## 说明

- 修复目标为 DSH 运行时编译 JS（`node_modules\@deepseek-ai\<包>\lib\index.js`）与用户插件。因这些是 DeepSeek 的编译产物，本仓库**只收录 diff patch 与报告**，不收录原始/修改后的完整文件（原始文件及 `.orig` 备份保留在本地）。
- 应用 patch：`git apply patches/<name>.patch` 或 `patch -p1 < patches/<name>.patch`。
- 5 项 defer（设计意图待定，未擅自改）见 `fix-ledger.md`「明确 defer」节。
- 改动需**重启 DSH** 才生效。
