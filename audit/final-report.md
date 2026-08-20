# DSH 全架构审计 — 最终分级报告

**审计范围/方法**：第一轮 9 个子代理对 DSH 全架构（231 包 / 781 编译后 JS 文件，源码根 `D:\Tools\DeepSeekHarness-Desktop\resources\dsh-runtime\node_modules\@deepseek-ai\`，另含 3 个自定义插件）做系统性 bug 排查并写入台账；第二轮以 AgentTeams 对抗性复核（t1 安全 / t2 并发状态机 / t3 LLM 流式）对第一轮的高危发现与遗留 UNCERTAIN 项逐行重查源码、追调用链，并用 Node v24 实测探针佐证。凡二次结论与第一轮冲突，**以二次独立裁定为准并标注**。

---

## 一、高危（HIGH）

### 1. [HIGH] SSRF — 任意 URL 私网/loopback/云元数据访问
`node_modules/@deepseek-ai/dsh-web-fetch-http/lib/index.js:22-33`

- **描述**：模型可见的 `web_fetch` 工具可令宿主进程 fetch 任意内网地址（含 loopback、RFC1918、link-local、云元数据 169.254.169.254）。
- **Root cause**：`validateFetchUrl` 只校验长度 / `http(s)` 协议 / 无内嵌凭据，**无任何 IP 级阻断**；`available()` 恒 `true`（:171）、无条件注册（:412）；`dsh-tool-web/lib/index.js:706` 的 `web_fetch` 直接 `ctx.web.fetch({url})` 走此 provider。包内文档（:99-100）自认 "Private-network and SSRF protection is not implemented"。
- **Evidence**：Node fetch 不带 `Origin`/`sec-fetch-site`，宿主对 `127.0.0.1:3080` 的 loopback fence 被绕过 → agent 可让宿主 fetch 自身 admin API 或云元数据端点。
- **Fix**：`validateFetchUrl` 增加 hostname→IP 解析并阻断 loopback / RFC1918 / link-local / metadata 段（须覆盖 IPv6 `::1`、十进制/八进制/hex 形态 IP、`0.0.0.0`）；redirect 虽 same-origin（:211），仍建议做连接级 IP 校验防 DNS-rebinding。
- **裁定**：第一轮 HIGH + 第二轮 t1 代码级**确认**，无冲突，维持 HIGH。

---

## 二、中危（MEDIUM）

### 2. [MEDIUM] client-connection 特权方法白名单漏列 → LAN 全盘枚举 + 建目录
`node_modules/@deepseek-ai/dsh-client-connection/lib/index.js:504-520`

- **描述**：webserver 绑 `0.0.0.0` 时，LAN 调用者可枚举宿主任意目录并写入（创建目录）。
- **Root cause**：`PRIVILEGED_METHODS` 钉住了 `host.pickDirectory`/`host.openPath`/`settings.*`/`credentials.*` 到 loopback，但**漏了 `host.listDirectory`/`host.createDirectory`**；browse 后端（`dsh-host-directory-picker-browse` :165-231）接受任意绝对路径、跟随 symlink、执行 mkdir。
- **Evidence**：代码 :492-493 自认该 fence "not authentication"，仅靠 trustedHosts（默认可能含 LAN IP）。
- **Fix**：把 `host.listDirectory` / `host.createDirectory` 两项加入 `PRIVILEGED_METHODS`。
- **裁定**：第一轮 MEDIUM + 第二轮 t1 代码级**确认**，无冲突。前置条件（绑 0.0.0.0 且 trustedHosts 含 LAN IP）已注明。

### 3. [MEDIUM] LLM tool-call id 兜底是死代码 → delta-only 流拼出空 id
`node_modules/@deepseek-ai/dsh-llm/lib/index.js:705 + :752`（TS 源 `lib/types/assembler.js:57 + :101`）

- **描述**：多 tool-call 时工具结果可能与调用错配。
- **Root cause**：`push` 对 `tool-call-delta` 无条件 `partial.toolCallId = chunk.id`（:705），而 `name` 走 `if (chunk.name)` 真值守卫（:706）——两字段不对称。`StreamChunk.id` 类型为必填 `CallId`（透传 string 不校验），两个 adapter 无 id 时都发 `CallId(block.callId ?? "")` = 空串；`??` 只在 null/undefined 兜底，对 `""` 永不触发。
- **Evidence**：deepseek `translate:328`/`closeBlock:213`、pi-ai `toStreamChunks:531`/`toolcall_start:513`；`dsh-session/lib/index.js:793-804` 白名单只要求 `typeof chunk.id === "string"`，`""` 合法。空 id 流入 `createToolResultMessage(:202)` 的 `toolCallId` 与 `serializeAssistant(:47)` 的 `tool_calls[].id`。
- **Fix**：仅当 `chunk.id !== ""` 才赋值（镜像 name 守卫），或 :752 用 `||` 替代 `??`；deepseek `closeBlock:213` 侧同样应在空 callId 时合成 `call-N`。
- **裁定**：第一轮 MEDIUM + 第二轮 t3 逐行**确认**，无冲突。（t3 诚实标注：现役 adapter 均发 block-end，故 :752 目前仅 delta-only 可达，但空 id 可另经 deepseek `closeBlock:213` 产生，潜在面更宽。）

### 4. [MEDIUM] pi-ai adapter 非 LlmError 原样 rethrow → 永不重试
`node_modules/@deepseek-ai/dsh-llm-pi-ai/lib/index.js:862`

- **描述**：pi-ai 传输/网络类失败被归为 `UNKNOWN`，不在可重试码表，静默放弃而非重试（与 deepseek 行为分歧）。
- **Root cause**：pi-ai stream 的 catch 只映射 timeout/abort，其余 `throw error`（:862）。下游 `adapterFailureChunk(dsh-llm:1393)` → `normalizeLlmFailure(:465)` → `harnessErrorCode(:532-534)` 对非 HarnessError 恒返 `"UNKNOWN"`；`DEFAULT_RETRYABLE_CODES(dsh-llm:360-366)` 不含 UNKNOWN；`dsh-llm-retry recover:138` 判 `!retryableCodes.includes(...)` 即 `return next()` 不重试。
- **Evidence**：对照 deepseek stream catch（:556）对残余错误包 `new LlmError(..., "TRANSPORT", {cause})`（可重试）。
- **Fix**：残余非 LlmError 包 `new LlmError("pi-ai request failed", "TRANSPORT", {cause: error})` 再 rethrow。
- **裁定**：第一轮 MEDIUM + 第二轮 t3 追完整调用链**确认**，无冲突。

### 5. [MEDIUM] file-uploads `attach()` 过早 clearInFlight → 孤儿化正在发送的文件
`D:\workspace\dsh-file-uploads\client.js:168`

- **描述**：上批仍在发送时用户选新文件，会清掉 inFlight 追踪，`promptError` → `restoreFailed()` 找不到可恢复数据，正在发送的文件引用被孤儿化。
- **Root cause**：`attach()` 在检查 composer phase **之前**就无条件 `clearInFlight(key)`。
- **Evidence**：`restoreFailed()` 依赖 inFlight 映射恢复；过早清除后恢复无据可依。
- **Fix**：把 `clearInFlight` 移到 `insertReference` 成功之后。
- **裁定**：第一轮 [中]（子代理 #9）；第二轮未单列复核此条（t1 仅在 sanitizer 面确认 file-uploads 的 [低] 项属实），维持第一轮 MEDIUM。

### 6. [MEDIUM / 语义] continuable 子代理在 `run_in_background:false` 时静默降级为一次性运行
`node_modules/@deepseek-ai/dsh-tool-subagent/lib/index.js:233-273`

- **描述**：`backgroundMode:"continuable"` + `run_in_background:false` 时无 durable subagentId，settle 后无法 `send_message` 追问。
- **Root cause**：`resolveDelegationRun(:126)` 返回 `{runInBackground:false}`，execute 走 :269 `settleForegroundRun(ctx.subagents.start(...))` 一次性运行。
- **Evidence**：一次性 start 返回 `{kind:"foreground", runId, output}`，无 subagentId。
- **Fix**：取决于设计意图——continuable 模式是否应让所有子代理可续；若应，则 foreground 路径也需返回/登记 durable id。
- **裁定**：第一轮列为 medium/uncertain-intent（真实语义 gap，非明确 correctness/security 缺陷）。第二轮未复核此条，维持原判，**标注为设计意图待定**，建议向实现者确认语义后再改。

---

## 三、低危（LOW）

### 7. [LOW] pwsh resolveWorkdir 不 canonicalize / 不用 workspaceRoot（bash/pwsh parity）
`node_modules/@deepseek-ai/dsh-tool-pwsh/lib/index.js:150-155`

- **描述**：沙箱化 pwsh 的默认与相对 workdir 基数与 bash 不一致。
- **Root cause**：pwsh 只 `import {isAbsolute, resolve}`（:1）、:368 传 `resolveWorkdir(args.workdir, exec)`；bash 双胞胎 `dsh-tool-bash/lib/index.js:177-183` 用 `policyWorkspaceRoot ?? canonicalPath(headerCwd)` 并 :394 传 `standingPolicy?.workspaceRoot`。
- **Evidence**：workspaceRoot 已 canonical（`dsh-sandbox-policy:79-81`），ACL/OS 强制在 resolved path 上，symlink cwd 无法逃逸 confinement。
- **Fix**：镜像 bash（import `canonicalPath`、签名加 `policyWorkspaceRoot`、:368 传 `standingPolicy?.workspaceRoot`）。
- **裁定**：第一轮 MEDIUM（疑逃逸）→ 第二轮 t1 **降级为 LOW**（非越权，是 parity bug）。**以二次裁定为准**。

### 8. [LOW] web-search-deepseek `available()` 凭据 disjunct 恒真
`node_modules/@deepseek-ai/dsh-web-search-deepseek/lib/index.js:98-101`

- **描述**：无 key 也报 available，`resolveProvider()` 误选 deepseek-official，搜索时才报 `WEB_PROVIDER_CREDENTIAL_MISSING`。
- **Root cause**：`(apiKey?.length > 0 || resolveApiKey !== void 0)` 因 `resolveOptions(:270-275)` 恒返回 `resolveApiKey` 函数，使 disjunct 恒真。
- **Fix**：`available()` 实测 key 存在（解析 resolver 或查 ambient env）。
- **裁定**：第一轮 LOW + 第二轮 t1 **确认并重述**，无冲突。

### 9. [LOW] LLM `blocks()` 在 max-tokens 时丢弃已完成的 tool-call 块
`node_modules/@deepseek-ai/dsh-llm/lib/index.js:773`（TS `lib/types/assembler.js:124`）

- **描述**：模型完成一个 tool call 后继续输出撞 max_tokens 时，已 block-end 关闭（参数完整、可安全执行）的 tool-call 块也被丢弃，丢失有效已完成工作。
- **Root cause**：`finish.kind==="max-tokens"` 时 `filter(block => block.type !== "tool-call")` 丢弃**全部** tool-call 块，与 JSDoc "drops tool calls that cannot be executed safely" 矛盾；代码可区分完整/截断（assemble:740 的 `partial.block`）却未区分。
- **Fix**：只丢弃未 block-end 关闭的 tool-call 块（`partial.block === undefined` 判 incomplete）。
- **裁定**：第一轮 UNCERTAIN → 第二轮 t3 **升级为确定 LOW**。**以二次裁定为准**。

### 10. [LOW] llm-retry `Retry-After > maxDelayMs` 时 normal 模式直接放弃
`node_modules/@deepseek-ai/dsh-llm-retry/lib/index.js:146-150`

- **描述**：可恢复的限流请求被静默丢弃而非 clamp 到 maxDelayMs。
- **Root cause**：`if (failure.providerRetryAfterMs > policy.maxDelayMs) { if (policy.mode === "normal") return next(); ... }` 把"预算超限"与"不可恢复"混用；normal 与 always 两分支不对称。
- **Fix**：统一 clamp 到 `policy.maxDelayMs`（或统一尊重 Retry-After），取决于意图。
- **裁定**：第一轮 LOW + 第二轮 t3 **确认**（补充：always 分支完全无视 provider Retry-After 更可疑）。无冲突。

### 11. [LOW] cordis-host-runner requiresApproval 状态校验成 no-op（&& 优先级）
`node_modules/@deepseek-ai/dsh-cordis-host-runner/lib/index.js:1753`

- **描述**：`requiresApproval===true` 时状态校验失效。
- **Root cause**：`latest.status !== expectedStatus && !pending.requiresApproval && latest.status !== "client-pending"` 因 `&&` > `||` 成为第三析取项；`!requiresApproval` 短路使整项恒 false。
- **Evidence**：`expectedStatus = pending.requiresApproval ? "awaiting-approval" : "starting-host"`（:1752）。后果被 `activate()` 的 in-flight 去重（:2187-2188）+ 幂等重挂（:2197）缓解。
- **Fix**：`latest.status !== expectedStatus && (pending.requiresApproval || latest.status !== "client-pending")`（显式分组）。
- **裁定**：第一轮 UNCERTAIN → 第二轮 t2 **确认 LOW**。**以二次裁定为准**。

### 12. [LOW] subprocess-local `undefined` 墓碑 env 在 node-pty 路径被字符串化
`node_modules/@deepseek-ai/dsh-subprocess-local/lib/index.js:318-331`

- **描述**：terminal(node-pty) 路径下 `undefined` 值 env 变成 `"FOO=undefined"` 字符串注入子进程环境。
- **Root cause**：`childEnv` 保留 `undefined` 值（POSIX `{...env,...extra}` / Windows `entries.push([key,value])`），依赖消费者解释 undefined=删除。Node `spawn` 会 drop（实测 `has:false`），但 `spawnTerminal`:996 走 node-pty，其 `_parseEnv`（`node-pty/lib/terminal.js:176-186`）`pairs.push(keys[i]+'='+env[keys[i]])` 隐式 String() 强转。
- **Evidence**：Node v24 实测 spawn 带 `{FOO:undefined}` 子进程 `has:false`；node-pty 源码逐字 `'='+env[key]`。
- **Fix**：`childEnv` 显式删除墓碑键（Windows 分支 `value===undefined` 不 push；POSIX 分支 delete 掉 undefined 键）。
- **裁定**：第一轮 UNCERTAIN → 第二轮 t2 **确认 LOW**（实测佐证）。**以二次裁定为准**。

### 13. [LOW] ACP `turn/end` 自身 append 失败时 error 被误报为 cancelled
`node_modules/@deepseek-ai/dsh-agent-loop/lib/index.js:592-597`（配合 `dsh-acp/lib/index.js:360`）

- **描述**：仅当 session 日志在 `turn/end` 边界持久化抛错（本身灾难性）时，`agent/error` 被去重、`turn/end` 永不落地，`whenIdle()` 以 `endReason===void 0` 误判 cancelled。
- **Root cause**：`throwError` 发 `agent/error` 被 :360 去重（return），但 `turn/end` append 失败 → 事件永不落地。
- **Fix**：`turn/end` append 失败路径不依赖 `agent/error` 兜底去重（或让 :360 去重条件区分"turn/end 是否已成功落地"）。
- **裁定**：第二轮 t2 对子代理 #5 反驳(b) 的**部分成立**裁定，LOW 边缘。**以二次裁定为准**。

### 14. [LOW] ACP `turnEndToStopReason` 内部 "aborted" 误映射 "end_turn"
`node_modules/@deepseek-ai/dsh-acp/lib/index.js:213-224`

- **描述**：harness 内部 "aborted" 被映射为 ACP "end_turn"，而 ACP spec "cancelled" 才对应 client 取消。
- **Root cause**：映射表语义错位；实际被 `cancel()`/`quiesce()` 的 `settlePrompt(record,"cancelled")` 提前 settle 掩盖。
- **Fix**：确认内部 aborted 与 client-cancel 的映射语义，必要时改映射。
- **裁定**：第一轮 [低] + 第二轮 t2 附带确认一致，低危/基本不可达。

### 15. [LOW] terminal-bash scrollback 行计数 off-by-one
`node_modules/@deepseek-ai/dsh-terminal-bash/lib/index.js:463 + :241`

- **描述**：输出以 `\n` 结尾时多出 phantom 空行 → `read()` 分页重叠、`maxLines` 提前丢一行真实内容。
- **Root cause**：`BoundedTextBuffer.append` 与 `LocalPtySession.read` 都按 `"\n"` split。
- **Fix**：split 后剔除尾部空串 / 按真实换行数计数。
- **裁定**：第一轮 [低]，第二轮未复核，维持。

### 16. [LOW] atomic-write `withFileLock` crash 遗留孤儿 `.lock`
`node_modules/@deepseek-ai/dsh-atomic-write/lib/index.js:72-95`

- **描述**：中途 crash 后每个写者永久超时（2s）无自愈，可能 brick `dsh-credentials-local` / `dsh-settings-file` 持久化。
- **Root cause**：锁文件无 crash 清理 / 过期回收。
- **Fix**：锁文件带 PID/时间戳 + 过期回收（stale lock 检测）。
- **裁定**：第一轮 [低]，第二轮未复核，维持。

### 17. [LOW] atomic-write rename 前不 fsync 文件/目录
`node_modules/@deepseek-ai/dsh-atomic-write/lib/index.js:37-41`

- **描述**：crash 可留截断/丢失文件，与 `dsh-fs-local`（做 `handle.sync()`）不一致。
- **Root cause**：`writeFileAtomic` rename 前缺 fsync。
- **Fix**：rename 前 fsync 文件（及必要时目录）。
- **裁定**：第一轮 [低]，第二轮未复核，维持。

### 18. [LOW] session-stats `turns` 少计 no-op turn
`node_modules/@deepseek-ai/dsh-session-stats/lib/index.js:126-132`

- **描述**：从 `step/end` 推导而非 `turn/start`，少计首 step 前被 reject/block 的 turn。
- **Root cause**：计数事件源选择不当。
- **Fix**：改用 `turn/start` 计数。
- **裁定**：第一轮 [低]，第二轮未复核，维持。

### 19. [LOW] session-checkpoint-policy 假定 signal 恒存在
`node_modules/@deepseek-ai/dsh-session-checkpoint-policy/lib/index.js:69`

- **描述**：`exec.signal.aborted` 在 signal 缺省时可能抛错。
- **Root cause**：未做 signal 存在性防御。
- **Fix**：`exec.signal?.aborted`。
- **裁定**：第一轮 [低/uncertain]，第二轮未复核，维持 low/uncertain。

### 20. [LOW] paste-input 单 catch 把一切失败映射 400 且回显 `cause.message`
`D:\Tools\dsh-plugins\dsh-paste-input\lib\index.js:508-511`

- **描述**：路径 / E* 码泄漏给调用方。
- **Root cause**：错误分类缺失，400/500 不分且回显内部 cause。
- **Fix**：区分 400（校验）/ 500（内部，generic body）。
- **裁定**：第一轮 [低]，第二轮未复核，维持。

### 21. [LOW] paste-input `readJson` 1MB cap 与 `maxFiles:10000` 冲突
`D:\Tools\dsh-plugins\dsh-paste-input\lib\index.js:92`（调用 :335）

- **描述**：几千文件的选择报 `JSON body exceeds 1048576 bytes`。
- **Fix**：按 `maxFiles` 调高 cap 或降低 `maxFiles`。
- **裁定**：第一轮 [低]，维持。

### 22. [LOW] file-uploads sanitizer 剥掉所有前导点（`.env`→`env`）
`D:\workspace\dsh-file-uploads\index.js:43`

- **描述**：`.env`→`env`、`.gitignore`→`gitignore`，`foo`/`.foo` 冲突；:48 的 `startsWith('.upload-')` guard 成死代码。
- **Fix**：仅剥临时文件前缀，或先存临时名再 sanitize。
- **裁定**：第一轮 [低] + 第二轮 t1 确认属实，维持。

### 23. [LOW] file-uploads 缺 Windows 保留设备名 + 尾随点/空格净化
`D:\workspace\dsh-file-uploads\index.js:40-56`

- **描述**：CON/PRN/AUX/NUL/COM1-9/LPT1-9 及尾随点/空格未净化（contrast `paste-input safeSegment:134-143` 有做）。
- **Fix**：镜像 paste-input 的 safeSegment。
- **裁定**：第一轮 [低] + 第二轮 t1 确认属实，维持。

### 24. [LOW] file-uploads `publishUnique` 用 hard link 不支持 FAT32/exFAT/网络挂载
`D:\workspace\dsh-file-uploads\index.js:213`

- **描述**：不支持 link 的文件系统 EPERM/ENOSYS → 上传 500。
- **Fix**：link 失败回退 rename / copyFile。
- **裁定**：第一轮 [低]，维持。

### 25. [LOW] subprocess-e2b `DSH_` 环境变量 scrub 大小写敏感
`node_modules/@deepseek-ai/dsh-subprocess-e2b/lib/index.js:57 + :69`

- **描述**：小写 `dsh_*` 凭据名逃过 scrub 并被远端 login shell 重注入。
- **Root cause**：`name.startsWith("DSH_")` 大小写敏感；孪生 `dsh-subprocess:48` 用 `toUpperCase()`，同文件 `SENSITIVE_ENV_PATTERN` 已是 `/i` 不敏感。
- **Fix**：两处 E2B 函数改 `name.toUpperCase().startsWith("DSH_")`。
- **裁定**：第一轮 [低]，第二轮未复核，维持。

---

## 四、已排除 / 非 bug 清单（负结果）

### 核心裁定：dsh-acp `agent/error` 去重条件 —— 最终裁定「故意去重，非写反」
`node_modules/@deepseek-ai/dsh-acp/lib/index.js:346-363`（配合 `dsh-agent-loop/lib/index.js:516-605`）

第一轮队长判「故意去重」，子代理 #5 反驳「写反了」。第二轮 t2 逐行追事件顺序**裁定队长正确**：

- `turn()`（:521）先算新 turn，:527 后写回 `phase.turn`。
- `turn/start` append 失败（:523-525）：`throwError` 发 `agent/error` 时 `phase.turn` 仍是旧 turn 且 message 尚未 claim（claim 在 preStep:496，晚于 turn/start），故 `inflight.turn === void 0`，:360 条件为 false → 立即 reject。此路径**永不发 turn/end**，必须由 `agent/error` 兜底。
- step 处理错误（:574-589）：`throwError` 时 `phase.turn` 已是新 turn、message 已 claim（`agent/inbox/claimed`:353-356 设 `inflight.turn`），:360 命中 → return 去重，交给 finally（:590-599）append 的 `turn/end{reason.kind:"error"}` 在 :347 reject。自洽。
- 子代理 #5 反驳 (a)「无关 turn 误拒 queued prompt」：ACP 桥内**不可达**（`prompt():429` 单 in-flight 保证 + serialized JSON-RPC）。反驳 (b)「同 turn 失败被掩盖为 cancelled」：**部分成立，LOW**（见本报告 §三.13，仅 `turn/end` 自身 append 失败时可达）。

**结论**：`if (record===void 0 || inflight===void 0 || inflight.turn === turn) return;` 是故意去重，非写反。

### 其余排除项（NOT bugs）
- **zip-slip `mediaEntryPath`**（`dsh-host-apiproxy/lib/types/session-export.js:70-72` 未净化 attachmentId）：不可利用——`readImage → ensureReference`（`dsh-attachment-local:83-87` `ID_PATTERN=/^sha256:([a-f0-9]{64})$/`）在 yield 前校验，非法 id 抛错使导出流 fail-loud，不写 traversal entry。（t1）
- **Exa/Perplexity apiKey 缺 `.role("secret")`**（`dsh-web-search-exa:136` / `perplexity:132`）：两者 `apply()` 均不调 `installSettingsSection`，Config 非 settings section，不进 settings redact 路径，无泄漏面。（t1）
- **dsh-api-remotes `credentials/updated(:21)`**：payload 仅 `ref`=环境变量名（REF_PATTERN），不含值，无凭据泄漏。（t1）
- **dsh-fs-sandbox `checkedTarget` 回退部署默认 policy**（:157-170）：canonicalize-then-contain + inode identity walk，无真实 bypass；:158 回退是 fail-closed（非 session workspace 被 deny）。（t1 判 NOT bug；t2 判 latent foot-gun——见 §五）
- **rpcFailure 回传原始 error.message**（dsh-host-apiproxy 多处）：仅 loopback/trustedHosts 可达，凭据域错误只含 ref 不含值，低信息泄漏非安全 bug。（t1）
- **dsh-code-runtime-worker-thread `exit` 恒当失败**（:904-909）：正确防御——Node v24 实测 2000/2000 次自然退出均 message 先于 exit（`finish` 同步置 `settled=true`，后续 exit 是 no-op）；exit 仅在 worker 未完成 done 协议就退出（模型 process.exit / isolate 崩溃）时触发，本就该判失败。（t2 实测）
- **readWholeBytes / readHostSource 未显式 destroy 流**（`dsh-fs-local:369-391` / `dsh-lsp-stdio:96-130`）：非 fd 泄漏——`createReadStream({signal})` abort 自动销毁；`for await` 的 break/throw 触发 AsyncIteratorClose → `return()` → `stream.destroy()`。实测两路径均 `ABORT_ERR` 后 `close`。（t2 实测）
- **dsh-fs-local `..` 越界**（:668-672）：doc 自认 "cwd 是 resolution default NOT containment boundary"；`..` 是正常解析非 vuln；`contains(:719-722)` 基于 realpath key 做 lexical relative，symlink 逃逸被 catch。（t1）
- **dsh-token-meter astral 字符 UTF-16 计 2**（:28-38）：在 `CHARS_PER_TOKEN=4` 文档化固定密度启发式下可接受，非 bug。（t3）
- **dsh-llm-retry `mode:"always"` 语义**（:131-137）：歧义（可能意为"无 retryableCodes 过滤"），非可证伪错误。（t3）
- **dsh-goal 状态机**（index.js/invariant.js/fold.js）：invariant 严谨（create/edit/pause/resume/complete/block/clear 各有 phase 转移校验，round 预算校验正确），无浅显 bug。
- **子代理 #1 负结果**（可信）：Inbox splice math、SurfaceManager 增量 fold、packChunkRuns dt/seq 编码、JSONL(zstd)/SQLite torn-tail 恢复、projection restoreFloor/restore off-by-one、sticky max-tokens turn ending、孤儿 retry chunk、deepFreeze(undefined)、FTS5 查询注入、JSONL 路径净化。

---

## 五、latent（当前不可达，非真实 bug，供记录）

- **dsh-jobs-local `settle` 未校验 outcome 非终态**（`lib/index.js:365-387`）：`job.status = outcome.status` 无 `isTerminal` 校验；现状所有 producer 均产终态，无调用可触发；若未来 producer resolve 非终态会"已 settle 但 status=running"。latent 健壮性缺口。（t2）
- **dsh-fs-sandbox `checkedTarget` 回退部署默认 policy**（`lib/index.js:157-170`）：`resolve()` 无 session 时返回部署根 `process.cwd()`，可能是更宽根；现状所有工具层调用者恒传显式 sandboxPolicy，不可达；doc 亦明言 "omit to use the deployment fallback"。latent foot-gun。（t2；t1 视为 fail-closed NOT bug，两者不矛盾——均认定当前无真实 bypass）

---

## 六、本地补丁问题专节（`D:\workspace\dsh-local-patches-backup\`，当前未应用）

> 说明：这 5 条来自第一轮台账，第二轮未针对此目录做二次复核，维持第一轮分级。

1. **[中] xlsx 路径硬编码旧目录** —— `restore.ps1` 的 `$defWin` 会重写（自洽）；但绕过 restore 则 Excel 静默失败。Fix=路径参数化或运行时探测。
2. **[中] readVisionConfig 硬编码 `G:\vision-files\dsh_vision_config.json`** —— 换机/换盘即失效。Fix=配置路径可配置/从设置读。
3. **[低] describeWithZhipu/Ollama 吞错误** —— 兜底信息不区分失败原因，难排障。Fix=保留 cause/错误码。
4. **[低] describeFilesLocally 用 `body.length`(UTF-16) + slice 截断 30000 字符** —— 可能切多字节字符。Fix=按 code point / 字节安全截断。
5. **[低] bingRssSearch 不传 signal** —— 中止无法取消 Bing 请求。Fix=签名加 signal + fetch 加 `{signal}`。（与台账 :26「patched/dsh-web-search-deepseek/lib/index.js:90-96」同源）

---

## 七、建议修复优先级排序

**P0（立即修，安全边界）**
1. SSRF `dsh-web-fetch-http`（§一.1）—— 唯一高危，模型可触发宿主内网/元数据访问。
2. `dsh-client-connection` PRIVILEGED_METHODS 漏列（§二.2）—— LAN 全盘枚举 + 写目录。

**P1（尽快修，正确性/可靠性）**
3. LLM tool-call id 兜底死代码（§二.3）—— 多 tool-call 结果错配。
4. pi-ai 非 LlmError 永不重试（§二.4）—— 网络抖动即失败且不恢复。
5. file-uploads `attach()` 过早 clearInFlight（§二.5）—— 正在发送的文件被孤儿化。

**P2（批量低危，成本低）**
6. pwsh/bpwsh workdir parity（§三.7）、web-search-deepseek available()（§三.8）、llm `blocks()` 丢弃完整 tool-call（§三.9）、llm-retry normal 放弃（§三.10）、cordis-host-runner 优先级（§三.11）、subprocess-local 墓碑 env（§三.12）、paste-input 错误映射/cap（§三.20-21）、file-uploads sanitizer/保留名/hard-link（§三.22-24）、subprocess-e2b scrub 大小写（§三.25）。

**P3（顺手/防御性）**
7. atomic-write 孤儿锁 + fsync（§三.16-17）、terminal-bash off-by-one（§三.15）、session-stats 计数（§三.18）、ACP aborted 映射（§三.14）、ACP turn/end 边界误报 cancelled（§三.13）。

**待澄清语义（不擅自改）**
- continuable + `run_in_background:false` 降级（§二.6）—— 需实现者确认意图。
- dsh-llm-retry `mode:"always"` 与 Retry-After 处理方向（§三.10）—— 需确认预算语义。

---

## 八、架构小结

DSH 的分层纪律整体极严：27 个核心包（agent/session 域）第一轮被判"无 high/medium 正确性 bug"，多数疑点经第二轮证实为有意设计（ACP `agent/error` 去重、worker-thread exit-as-failure、sandbox fail-closed、fd 经 signal+iterator 自动释放）。真正的缺陷集中收敛在三处边界：

1. **信任边界**：SSRF 与 client-connection 特权方法白名单漏列，都源于"宿主 loopback fence 被当作认证"——loopback/IP fence 只防远程不防"经宿主进程中转"的请求，这是本轮最高价值发现。
2. **跨 adapter 行为不对称**：LLM 层 deepseek 与 pi-ai 在错误分类（TRANSPORT vs UNKNOWN）、tool-call id 兜底（`??` vs 空串）、retry 语义上各自为政，是流式/可靠性缺陷的温床，也是"shared assembler + 每 adapter 各自翻译"架构的固有张力。
3. **防御性/健壮性缺口**：atomic-write 孤儿锁、subprocess 墓碑 env、sanitizer 边界、off-by-one 等，多为 crash/极端路径才触发的低危项，体现"正常路径极严、异常路径留缝"的分布。

建议后续把安全边界（SSRF/IP fence）作为第一优先级，把两个 LLM adapter 的错误分类与 id 拼装统一到 shared 层（消除 adapter 分歧的根因），再批量清低危与本地补丁。
