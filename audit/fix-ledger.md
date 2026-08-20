# DSH 修复台账 (fix-ledger)

审计报告见 `final-report.md`（1 高危 / 5 中危 / 19 低危 / 2 latent / 13+ 排除）。本台账记录**已实际应用到运行中 DSH 源码**的修复 + 明确 defer 的项。

## 环境与协议
- 修复目标 = 运行中 DSH 的 stock 编译 JS（`D:\Tools\DeepSeekHarness-Desktop\resources\dsh-runtime\node_modules\@deepseek-ai\<包>\lib\index.js`）与用户自有插件（`D:\workspace\dsh-file-uploads\`、`D:\Tools\dsh-plugins\dsh-paste-input\`）。
- 每文件改前备份原文件到 `D:\workspace\dsh-audit\fix-backups\<包>\index.js.orig`；改后 `node --check`；非平凡逻辑留 runnable check 在 `D:\workspace\dsh-audit\fix-checks\`。
- 改动对运行中进程（PID 27220）不生效，**需重启 DSH 才加载新代码**。
- 执行者：AgentTeams `dsh-fix-pass`（security/llm/tools/plugins 4 成员）+ 队长（P3 存储/终端）。

## 已应用修复

### P0 安全
1. **[高] SSRF 阻断** — `@deepseek-ai\dsh-web-fetch-http\lib\index.js`（security）
   - 新增 `isIP`(node:net)/`lookup`(node:dns/promises) import + `bareHost`/`isBlockedIpv4`/`isBlockedIpv6`/`isBlockedHostname`/`assertNotPrivateHost`/`assertNotPrivateResolve`。
   - `validateFetchUrl`(:94) 加 `assertNotPrivateHost(url.hostname)`（同步阻断私网/loopback/link-local/元数据 IP + localhost/.local/.internal 主机名）；`followAndRead`(:259) 加 `await assertNotPrivateResolve(...)`（连接前 DNS 解析阻断，防 hostname→私网 + DNS rebinding）。
   - **成员抓到我原稿 bug**：Node 把 `::ffff:127.0.0.1` 规范化为十六进制 `::ffff:7f00:1`，原 `::ffff:` 分支按点分十进制解析漏网；已改为「尾随含 `.` 走点分、否则按 2-hextet 十六进制拆回点分」。
   - 验证：`ssrf-check.mjs` 11/11 URL 抛 `WEB_BLOCKED_URL`，exit 0（队长独立复跑通过）。备份 `fix-backups\dsh-web-fetch-http\index.js.orig`。
2. **[中] PRIVILEGED_METHODS 补漏** — `@deepseek-ai\dsh-client-connection\lib\index.js:511-512`（security）
   - Set 加 `"host.listDirectory"`、`"host.createDirectory"`。验证 `node --check` OK。

### P1 LLM（llm 成员）
3. **[中] tool-call id 兜底死代码** — `@deepseek-ai\dsh-llm\lib\index.js:705`：`partial.toolCallId = chunk.id` → `if (chunk.id) partial.toolCallId = chunk.id`（镜像 name 守卫，空串不赋值让 :752 `?? CallId()` 生效）。runnable check `llm-id-check.mjs` 驱动真实 BlockAssembler 断言 delta-only 空 id 流最终 toolCallId==="call-0"，PASS。
4. **[中] pi-ai 非 LlmError 不重试** — `@deepseek-ai\dsh-llm-pi-ai\lib\index.js:862-863`：加 `if (error instanceof LlmError) throw error;` + 残余包 `new LlmError("pi-ai request failed","TRANSPORT",{cause:error})`（镜像 deepseek，可重试）。
5. **[低] blocks() max-tokens 丢已完成 tool-call** — `@deepseek-ai\dsh-llm\lib\index.js:773`：只丢 `block===undefined`（未 block-end 关闭）的 tool-call 块，保留已关闭可执行者。
6. **[低] llm-retry Retry-After 不对称** — `@deepseek-ai\dsh-llm-retry\lib\index.js:146-148`：删 normal 模式 `return next()` 放弃分支，统一 clamp 到 `maxDelayMs`。

### P2 工具/子进程（tools 成员）
7. **[低] pwsh workdir parity** — `@deepseek-ai\dsh-tool-pwsh\lib\index.js`：resolveWorkdir 镜像 bash（+`canonicalPath` import、+`policyWorkspaceRoot` 参数、调用处传 `standingPolicy?.workspaceRoot`）。静态比对与 `dsh-tool-bash:177-183` 逐字一致。
8. **[低] web-search-deepseek available() 恒真** — `@deepseek-ai\dsh-web-search-deepseek\lib\index.js`：改测 `hasApiKey`（字面 key 或 ambient env），删恒真 disjunct。**已知限制**：`available()` 同步，credentials-plane `.credentials.yaml` 独存 key 无法同步探测（忠实标注）。
9. **[低] cordis-host-runner 优先级 no-op** — `@deepseek-ai\dsh-cordis-host-runner\lib\index.js:1753`：加括号 `latest.status !== expectedStatus && (pending.requiresApproval || latest.status !== "client-pending")`。
10. **[低] subprocess-local 墓碑 env** — `@deepseek-ai\dsh-subprocess-local\lib\index.js:318-331`：POSIX 分支 delete undefined 键、Windows 分支 `value===undefined` 不 push。
11. **[低] subprocess-e2b scrub 大小写** — `@deepseek-ai\dsh-subprocess-e2b\lib\index.js:57+:69`：两处 `name.startsWith("DSH_")` → `name.toUpperCase().startsWith("DSH_")`。

### P3 存储/终端（队长）
12. **[低] atomic-write rename 前不 fsync** — `@deepseek-ai\dsh-atomic-write\lib\index.js`：`writeFile` → `open(temp,"wx",mode)` + `handle.writeFile` + `handle.sync()` + `handle.close()`，再 rename。验证 `node --check` OK。
13. **[低] terminal-bash 行计数 off-by-one** — `@deepseek-ai\dsh-terminal-bash\lib\index.js:241+:463`：split 后按「尾随空串」修正行数（append 用 `count=lines.length-(last===""?1:0)` 并 `slice(count-maxLines)` 保留尾随 \n；read 的 totalLines 同步修正）。runnable check `terminal-lines-check.mjs` ALL PASS。
14. **[低] session-stats turns 少计 no-op turn** — `@deepseek-ai\dsh-session-stats\lib\index.js`：新增 `turn/start` 分支递增 `turns`，`step/end` 去掉 `turns`/`lastTurn` 计数（只计 steps），删 `lastTurn` init。验证 `node --check` OK。

### P2 自定义插件（plugins 成员，备份在 `dsh-local-patches-backup\fileuploads-pasteinput-20260820-131146\`）
15. **[中] file-uploads clearInFlight 过早** — `D:\workspace\dsh-file-uploads\client.js:166-178`：`clearInFlight(key)` 从 `attach()` 开头移到 `insertReference` 成功之后，避免发送中新选文件时清掉 inFlight 追踪。
16. **[低] file-uploads sanitizer 剥前导点** — `dsh-file-uploads\index.js`：保留前导点（`.env` 不再变 `env`），`.upload-` 临时前缀逻辑恢复。
17. **[低] file-uploads Windows 保留名/尾随点空格** — `dsh-file-uploads\index.js`：镜像 paste-input `safeSegment`（CON/PRN/AUX/NUL/COM1-9/LPT1-9 + 尾随点/空格净化）。
18. **[低] file-uploads hard-link 失败** — `dsh-file-uploads\index.js:213`：`link()` 失败（FAT32/exFAT/网络挂载 EPERM/ENOSYS）回退 `copyFile`。
19. **[低] paste-input 错误映射** — `D:\Tools\dsh-plugins\dsh-paste-input\lib\index.js`：`ValidationError` 区分 400（校验）/500（内部，generic body 不回显 `cause.message`）。
20. **[低] paste-input 1MB cap** — `dsh-paste-input\lib\index.js`：`readJson` cap 按 `maxFiles` 调高（10000→10MB）。

> 后续已修：`dsh-file-uploads\upload-manager.test.js` 既有缺陷（静态+动态 `import '../index.js'` 路径错、:19 断言与新行为冲突）已修复——import 改 `./index.js`（两处）、:19 断言改 `file-.upload-secret`、补 `.env` 前导点保留断言。`node --test` 7/7 pass。

## 明确 defer（不擅改，附理由）
- **[低] atomic-write 孤儿 .lock 永久超时**（`withFileLock:72-95`）：包注释明言「orphan recovery 是 operator action，file age 不能证明 owner 已停」。naive 的 PID 死检 + `rm` 回收存在「两写者同时抢收」竞态（比可用性 brick 更糟=数据损坏）；安全回收需原子 rename-reclaim 设计。留给包作者或单独设计。
- **[低] ACP `turnEndToStopReason` aborted→end_turn 映射**（`dsh-acp:213-224`）：语义待实现者确认，实际被 cancel/quiesce 提前 settle 掩盖，基本不可达。
- **[低] ACP turn/end append 失败误报 cancelled**（`dsh-agent-loop:592-597`）：仅 session 日志持久化抛错（灾难性路径）才触发，改需重构错误去重语义。
- **[中/语义] continuable + run_in_background:false 降级**（`dsh-tool-subagent:233-273`）：设计意图待实现者确认。
- **[低/语义] llm-retry mode:"always" 语义**（`dsh-llm-retry:131-137`）：歧义，非可证伪错误。

## 终验结果（全量）
- `node --check`：13 个 stock 文件 + 3 个插件文件 = **16/16 OK**（0 失败）。
- runnable check：`ssrf-check.mjs`（11/11 阻断）、`llm-id-check.mjs`（toolCallId="call-0"）、`terminal-lines-check.mjs`、`dsh-file-uploads\sanitizer-check.js`（13 用例）——全部 PASS，exit 0。

## 生效须知
- 所有改动对运行中进程（PID 27220）不生效，**需重启 DSH 才加载新代码**。
- 回滚：`fix-backups\<包>\index.js.orig`（13 个 stock 文件）+ `dsh-local-patches-backup\fileuploads-pasteinput-20260820-131146\`（3 个插件文件）。
