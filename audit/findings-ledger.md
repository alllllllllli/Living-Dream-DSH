# DSH 架构审计 — 发现台账 (findings ledger)

目标: 系统性排查 DSH 全架构真实 bug，产出分级报告并修复高价值问题。
goal-9cf680b4-2f9d-4112-aa89-5ba4cee1fbeb (rev1)

## 已亲自验证并排除的候选 (NOT bugs)

### dsh-acp `agent/error` 条件 (line 357-363) — 已排除，非 bug
- 文件: `node_modules\@deepseek-ai\dsh-acp\lib\index.js`
- 疑点: `if (record===void 0 || inflight===void 0 || inflight.turn === turn) return;` 看起来像"match 时跳过拒绝"。
- 验证结论 (读 `dsh-agent-loop/lib/index.js` 事件顺序确认):
  - `turn()` (line 516-605): `preStep`→`inbox.claim`→`claimed` 回调→emit `agent/inbox/claimed` (设置 `inflight.turn`)。
  - 出错路径: `catch` 里 `this.throwError(error)` (line 589) → emit `agent/error`(line 470, 先) → rethrow → `finally` 里 `session.append("turn/end", {reason:{kind:"error"}})` (line 592, 后)。
  - 所以 `agent/error` 先于 `turn/end` 触发；`turn/end` 处理器(line 346-351) 在 `inflight.turn === event.data.turn` 且 `reason.kind==="error"` 时 reject。
  - `agent/error` 的 `inflight.turn === turn → return` 是**故意去重**: match 时交给后续 `turn/end` 拒绝；只有不 match (message 尚未 claim，`inflight.turn===void 0`，如 `turn/start` append 失败 line 523-525，此时无 turn/end) 才由 `agent/error` 兜底 reject。逻辑自洽，非 bug。

## 本地补丁问题 (<workspace>\dsh-local-patches-backup\，当前未应用)
1. [中] xlsx 路径硬编码旧目录 (restore.ps1 $defWin 会重写，自洽；绕过 restore 则 Excel 静默失败)
2. [中] readVisionConfig 硬编码 `<vision-config-dir>\dsh_vision_config.json`
3. [低] describeWith<vision-provider>/<local-llm> 吞错误，兜底信息不区分原因
4. [低] describeFilesLocally 用 body.length(UTF-16)+slice 截断 30000 字符，可能切多字节
5. [低] bingRssSearch 不传 signal，中止无法取消

## 新增独立结论 (本轮)
- [低] `dsh-acp/lib/index.js` `turnEndToStopReason`(line 213-224): harness 内部 "aborted" 映射为 ACP "end_turn"，但 ACP spec StopReason "cancelled" 才对应 client 取消。实际被 `cancel()`/`quiesce()` 直接 `settlePrompt(record,"cancelled")` 提前 settle 掩盖，仅内部 abort 不经 cancel 时可达，低危/基本不可达。
- [已确认,低] 补丁 `patched/dsh-web-search-deepseek/lib/index.js` line 90-96: `bingRssSearch(query)` 签名无 signal，line 142 `search()` 调用时也不传 signal，fetch 无 `{signal}`，中止无法取消 Bing 请求。修复=签名加 signal + fetch 加 `{signal}`。
- dsh-goal 包 (index.js/invariant.js/fold.js): 状态机 invariant 严谨(create/edit/pause/resume/complete/block/clear 各有 phase 转移校验，round 预算校验 `source.round === roundsStarted+1 && <= maxGoalRounds`)，无浅显 bug。"blocked 最小轮数" 是工具层策略，不在 dsh-goal 内。
- ACP 语义澄清: `dsh-acp`=Agent Client Protocol(stdio 桥)，`dsh-acp-snapshot`=快照测试 harness；两者都不是我系统提示里的 Active Context Pruning(即 compress/decompress/acp_status 背后的 block ledger，属 dsh-compaction*)。

## 子代理 #2 tools 报告 (f6f83bff，已完成，已亲自验证)
- [中] `node_modules\@deepseek-ai\dsh-tool-pwsh\lib\index.js:150-155` — `resolveWorkdir(modelWorkdir, exec)` 只用原始 `headerCwd`，不 canonicalize、不用 sandbox `workspaceRoot`；bash 双胞胎 `dsh-tool-bash\lib\index.js:177-183` 用 `policyWorkspaceRoot ?? canonicalPath(headerCwd)`。**已亲自确认**: bash 从 `@deepseek-ai/dsh-sandbox` import `canonicalPath`(line 5)且调用点 :394 传 `standingPolicy?.workspaceRoot`；pwsh 只 import `{isAbsolute, resolve}`(line 1)、调用点 :368 是 `resolveWorkdir(args.workdir, exec)`。后果=沙箱化 pwsh 的 workdir 可能通过 symlink/非规范化路径解析出自身 confinement 栅栏外，或与 bash 不一致。Fix=镜像 bash：import `canonicalPath`、签名加 `policyWorkspaceRoot`、`sessionCwd = policyWorkspaceRoot ?? (headerCwd===void 0 ? void 0 : canonicalPath(headerCwd))`、:368 传 `standingPolicy?.workspaceRoot`。
- UNCERTAIN(tools): `dsh-tool-workflow:130-133` maxResultChars 只截 JSON value 不含 header(可能故意)；`dsh-tool-fs-search:187` handle.done rejection 恒 re-throw SEARCH_FAILED 即使并发 abort(低置信)。

## 子代理 #7 sandbox+fs+shell 报告 (074bd564，已完成)
- [中] `node_modules\@deepseek-ai\dsh-terminal-bash\lib\index.js:463` + `:241` — scrollback 行计数 off-by-one：`BoundedTextBuffer.append` 与 `LocalPtySession.read` 都按 `"\n"` split，输出以 `\n` 结尾(常态)时多出一个 phantom 空行 → `read()` 分页重叠(`offset=1`≈`offset=0`)、`maxLines` 提前丢一行真实内容。
- [低] `node_modules\@deepseek-ai\dsh-atomic-write\lib\index.js:72-95` — `withFileLock` crash 后遗留孤儿 `<file>.lock`，之后每个写者永久超时(2s)无自愈；它支撑 dsh-credentials-local + dsh-settings-file，中途 crash 会 brick 凭据/设置持久化。
- [低] `node_modules\@deepseek-ai\dsh-atomic-write\lib\index.js:37-41` — `writeFileAtomic` rename 前不 fsync 文件/目录，crash 可留截断/丢失文件；与 `dsh-fs-local`(做 `handle.sync()`) 不一致。
- UNCERTAIN: dsh-fs-sandbox `checkedTarget` 在工具层缺 sandboxPolicy 时回退部署默认 policy(错误 session root)；readHostSource/readWholeBytes 超限/abort 路径未显式 destroy createReadStream(fd 挂到 GC)；自定义 runnerCommand 恒包 bwrap 参数却声称 full enforcement。

## 子代理 #9 自定义插件报告 (9ce542c3，已完成)
- [中] `<workspace>\dsh-file-uploads\client.js:168` — `attach()` 在检查 composer phase 前就无条件 `clearInFlight(key)`，用户在上批仍在发送时选新文件会清掉 inFlight 追踪 → `promptError`→`restoreFailed()` 找不到可恢复数据，正在发送的文件引用被孤儿化。Fix=把 clearInFlight 移到 insertReference 成功之后。
- [低] `<dsh-install>\dsh-plugins\dsh-paste-input\lib\index.js:508-511` — 单 catch 把一切失败映射 400 且回显 `cause.message`(路径/E* 码泄漏给调用方)。Fix=区分 400(校验)/500(内部，generic body)。
- [低] `dsh-paste-input\lib\index.js:92`(调用 :335) — `readJson` 默认 1MB cap 与 `maxFiles:10000`(:26) 冲突，几千文件的选择会 `JSON body exceeds 1048576 bytes`。
- [低] `dsh-file-uploads\index.js:43` — sanitizer `.replace(/^\.+/,'')` 剥掉所有前导点(非仅临时文件前缀)：`.env`→`env`、`.gitignore`→`gitignore`、`foo`/`.foo` 冲突；:48 的 `startsWith('.upload-')` guard 成死代码。
- [低] `dsh-file-uploads\index.js:40-56` — 缺 Windows 保留设备名(CON/PRN/AUX/NUL/COM1-9/LPT1-9)+尾随点/空格净化(contrast paste-input safeSegment :134-143 有做)。
- [低] `dsh-file-uploads\index.js:213` — `publishUnique` 用 `link()` hard link，FAT32/exFAT/网络挂载不支持(EPERM/ENOSYS)→上传 500。Fix=link 失败回退 rename/copyFile。
- UNCERTAIN: file-uploads client.js:219-226 stale serializing 标志；remove() 假定每引用占 1 字符(client.js:189 / paste-input client.js:1055)；paste-input sourceTrustedHosts 找不到时返回 [] 使非 loopback Host 全 403；client.js:665 blockEnd 缩进标记欠计。

## 子代理 #8 host+api+web 报告 (3ddad2ae，已完成；SSRF 已亲自验证)
- **[高] SSRF** `node_modules\@deepseek-ai\dsh-web-fetch-http\lib\index.js:22-33` — `validateFetchUrl` 只校验长度/http(s)/无内嵌凭据，**无 loopback/私网/RFC1918/link-local/云元数据(169.254.169.254) 阻断**；`available()` 恒 true(:171)、无条件注册(:412)。**已亲自验证**: `dsh-tool-web\lib\index.js:637,706` 的模型可见 `web_fetch` 工具直接 `ctx.web.fetch({url}, signal)` → 走此 provider；Node fetch 不带 Origin/sec-fetch-site，host 对 127.0.0.1:3080 的 loopback fence 被绕过 → agent 可让 host fetch 自身 admin API / 云元数据。模块 doc(:99-100) 明言 "Private-network and SSRF protection is not implemented; do not enable this provider where it can reach sensitive internal targets." Fix=validateFetchUrl 增加 hostname→IP 解析 + 阻断 loopback/私网/RFC1918/link-local/metadata 段。
- [中] `node_modules\@deepseek-ai\dsh-client-connection\lib\index.js:504-520` — `PRIVILEGED_METHODS` 钉住 host.pickDirectory/host.openPath/settings.*/credentials.* 到 loopback，但漏了 `host.listDirectory`/`host.createDirectory`；browse 后端(:165-231) 接受任意绝对路径、跟 symlink、建目录 → webserver 绑 0.0.0.0 时 LAN 调用者可枚举全盘+写目录。
- [低] `dsh-web-search-deepseek\lib\index.js:98-101` — `resolveApiKey` 恒为函数使凭据 disjunct 恒真，无 key 也报 available → `resolveProvider()` 误选/歧义。
- UNCERTAIN: dsh-host-apiproxy:91-93 `mediaEntryPath` 未净化 attachmentId 插 ZIP entry(zip-slip)；Exa/Perplexity apiKey 缺 `.role("secret")`；`rpcFailure` 回传原始 error.message。

## 子代理 #3 subagent+goal 报告 (1c686a4a，salvage 后写入 subagent-goal-findings.md)
- [中/语义] `node_modules\@deepseek-ai\dsh-tool-subagent\lib\index.js:233-273` — `backgroundMode:"continuable"` + `run_in_background:false` 时，`resolveDelegationRun`(:126) 返回 `{runInBackground:false}`，execute 走 :269 `settleForegroundRun(ctx.subagents.start(...))` 一次性运行，**无 durable subagentId**，settle 后无法 send_message 追问。即 `run_in_background:false` 静默放弃 continuable 语义(尽管工具描述:141 只把它说成"等结果")。已亲自确认代码路径属实；是否算 bug 取决于设计意图(continuable 模式是否应让所有子代理可续)。倾向=真实语义 gap，但非明确 correctness/security 缺陷，列 medium/uncertain-intent。

## 子代理 #1 agent+session 报告 (b64a49c3，已完成)
- 结论: 无 high/medium 正确性 bug；27 个包纪律极严，多数疑点均证实为有意设计。
- [低] `dsh-session-stats\lib\index.js:126-132` — `turns` 计数从 `step/end` 转移推导而非 `turn/start`，少计 no-op turn(首 step 前被 reject/block 的 turn)。
- [低/uncertain] `dsh-session-checkpoint-policy\lib\index.js:69` — `exec.signal.aborted` 假定 signal 恒存在。
- 排除项(负结果可信): Inbox splice math、SurfaceManager 增量 fold、packChunkRuns dt/seq 编码、JSONL(zstd) 与 SQLite torn-tail 恢复、projection restoreFloor/restore off-by-one、sticky max-tokens turn ending、孤儿 retry chunk、deepFreeze(undefined)、FTS5 查询注入、JSONL 路径净化。

## 子代理 #6 LLM 报告 (8266fe5c，salvage 后写入 llm-findings.md)
- [中] `dsh-llm\lib\index.js:752`(配合 :705) — tool-call id 兜底 `partial.toolCallId ?? CallId(\`call-${index}\`)` 是死代码：`push` 恒赋 `partial.toolCallId = chunk.id`(adapters 发 `CallId(block.callId ?? "")`，恒字符串可能 `""`)，`??` 永不触发 → delta-only 流拼出空 `id` 而非 `call-N`。Fix=仅 `chunk.id !== ""` 时赋，或 `partial.toolCallId || CallId(...)`。
- [中] `dsh-llm-pi-ai\lib\index.js:862` — 非 LlmError 迭代失败原样 rethrow → 归为 `UNKNOWN`、不在 `DEFAULT_RETRYABLE_CODES` 永不重试；deepseek 则包成 `TRANSPORT`(可重试)。Fix=残余非 LlmError 包 `new LlmError(...,"TRANSPORT",{cause})` 再 rethrow。
- [低] `dsh-llm-retry\lib\index.js:146-150` — `Retry-After > maxDelayMs` 且 mode=normal 时直接 `return next()` 放弃请求而非 clamp 到 maxDelayMs，丢可恢复的限流请求。
- UNCERTAIN: dsh-token-meter:28-38 按 UTF-16 `length` 计 astral 字符=2(有意的 CHARS_PER_TOKEN=4 启发式)；dsh-llm:773 max-tokens 时 `blocks()` 丢弃全部 tool-call 块含已 block-end 关闭的(有意防御)；dsh-llm-retry:131-137 mode="always" 语义歧义。

## 子代理 #4 workflow+jobs+schedule 报告 (d3dcfdcd，已完成)
- 结论: 编排/teardown 核心经逐行追踪质量极高，仅确认到 low-severity 环境变量 scrub 大小写不一致。
- [低] `node_modules\@deepseek-ai\dsh-subprocess-e2b\lib\index.js:57`(及 :69) — `scrubRemoteEnvironment`/`bootstrapEnvironment` 用 `name.startsWith("DSH_")` 大小写敏感匹配，而孪生 `dsh-subprocess\lib\index.js:48` 用 `key.toUpperCase().startsWith("DSH_")`、同文件 `SENSITIVE_ENV_PATTERN` 已是 `/KEY|PASSWORD|SECRET|TOKEN/i` 不敏感。→ 小写 `dsh_*` 凭据名逃过 scrub 并被远端 login shell 重注入。Fix=两处 E2B 函数都改 `name.toUpperCase().startsWith("DSH_")`。
- UNCERTAIN: dsh-cordis-host-runner:1753 requiresApproval 使状态校验成 no-op(无法构造可达路径)；dsh-code-runtime-worker-thread:904-909 exit 恒当失败(依赖 postMessage 先于 exit 的隐式约定)；dsh-subprocess-local:318-331 undefined 墓碑值依赖 spawn 把 undefined env 当 unset；dsh-jobs-local:365-387 job.status 未校验 producer 非终态。

## 第二轮 AgentTeams 对抗性复核 (team dsh-audit-second-pass, 4 成员: security/concurrency/llm/reviewer)
方式: 队长=本会话；成员=continuable 子代理(jiyuan/deepseek-v4-pro-0813)；t1/t2/t3 并行复核 + t4(reviewer 依赖前三) 汇总落盘 final-report.md。

### t1 安全复核 (security)
- [高] 确认 SSRF `dsh-web-fetch-http\lib\index.js:22-33` validateFetchUrl 无 loopback/私网/RFC1918/link-local/169.254.169.254 阻断；Fix=hostname→IP 解析阻断(覆盖 IPv6 ::1/十进制/八进制/hex IP/0.0.0.0)+连接级 IP 校验防 DNS-rebinding。
- [中] 确认 `dsh-client-connection\lib\index.js:504-520` PRIVILEGED_METHODS 漏 host.listDirectory/host.createDirectory(前置: 绑 0.0.0.0 + trustedHosts 含 LAN IP)。
- [低→降级] `dsh-tool-pwsh\lib\index.js:150-155` resolveWorkdir 从第一轮 [中] 降为 [低] parity bug——symlink cwd **不逃逸** confinement，仅与 bash 不对称，非越权。
- [低] 确认 `dsh-web-search-deepseek\lib\index.js:98-101` available() 凭据 disjunct 恒真(无 key 也报 available)。
- 排除(非 bug): zip-slip(attachmentId 有 ensureReference ID_PATTERN 拦截)、Exa/Perplexity apiKey 缺 .role("secret")(非 settings section 无泄漏面)、api-remotes credentials/updated(只传 ref)、dsh-fs-sandbox containment(canonicalize-then-contain 无 bypass)、rpcFailure error.message(仅 loopback/trustedHosts)。
- 同类面无新漏洞: readHostSource(LSP)正确 contained、dsh-fs-local 非边界、file-uploads sanitizer 已防 traversal。

### t2 并发/状态机复核 (concurrency)
- **`agent/error` 争议最终裁定: 第一轮队长「故意去重」正确，非写反。** 证据: `inflight.turn` 仅 `agent/inbox/claimed`(dsh-acp:353-356) 赋值，claim 在 preStep(agent-loop:496) **晚于** turn/start append(agent-loop:523)；故 turn/start 失败时 inflight.turn===void 0 → :360 条件 false → agent/error 立即 reject(兜底, 该路径永不发 turn/end)；claim 后 step 错误(agent-loop:589) inflight.turn===当前turn → :360 return 去重, 且 claim 后错误必然经 finally(590-599) 发 turn/end{kind:"error"} 由 :347 reject。子代理#5 的 (a) 不可达(单 in-flight 保证)，(b) 仅 turn/end 自身 append 失败(agent-loop:592-597)会误报 cancelled(LOW 边缘)。
- [低] NEW `dsh-cordis-host-runner\lib\index.js:1753` — `!requiresApproval` 因子使 `&&` 优先级下第三析取项恒 false，requiresApproval 请求的状态校验成 no-op(被 activate in-flight 去重缓解)。Fix=加括号。
- [低] NEW `dsh-subprocess-local\lib\index.js:318-331` — childEnv undefined 墓碑在 node-pty terminal 路径被 `_parseEnv` 强转字符串 "undefined"(Node spawn 会 drop, 实测 has:false)；仅 terminal 路径可达。Fix=显式删墓碑键。
- 排除(非 bug): worker-thread:904-909 exit 恒失败=正确防御(settled 标志+实测 message 2000/2000 先于 exit)；readWholeBytes/readHostSource fd 经 signal 自动销毁+async iterator return() 释放(ABORT_ERR+close 双路径实测)。
- latent(当前不可达, 非真实 bug): jobs-local:365 settle 未校验 outcome 终态(所有 producer 现均产终态)；fs-sandbox checkedTarget 回退(工具层恒传显式 policy)。
- 探针脚本在 <workspace>\dsh-audit\concurrency-probe\。

### t3 LLM 复核 (llm)
- [中] 确认 `dsh-llm\lib\index.js:705+:752`(TS lib/types/assembler.js:57+:101) tool-call id 兜底 `?? CallId(call-N)` 死代码(push 无条件赋值 + id 恒 string/空串 + ?? 不兜空串 → delta-only 流拼空 id)；证据 dsh-commands/lib/typert.host.js:418 声明 id:CallId、dsh-session:793-804 只校验 typeof string。
- [中] 确认 `dsh-llm-pi-ai\lib\index.js:862` 非 LlmError 原样 rethrow → normalizeLlmFailure(:465)/harnessErrorCode(:532) 归 UNKNOWN → DEFAULT_RETRYABLE_CODES(:360) 不含 UNKNOWN → 永不重试；deepseek:556 包 TRANSPORT 可重试。
- [低] 确认 `dsh-llm-retry\lib\index.js:146-150` Retry-After>maxDelayMs 时 normal 放弃 vs always clamp 不对称。
- [低] NEW(升级自第一轮 UNCERTAIN) `dsh-llm\lib\index.js:773`(TS:124) blocks() 在 max-tokens finish 时 filter 丢弃【全部】tool-call 块(含已 block-end 关闭、参数完整可安全执行者)，与 JSDoc 矛盾；代码可区分完整/截断(assemble:740 partial.block)却未区分。Fix=只丢 partial.block===undefined 的未关闭块。
- UNCERTAIN 维持: token-meter estimateContent UTF-16 astral 计数(CHARS_PER_TOKEN=4 启发式, 可接受)；retry mode="always" 语义歧义；foldSurfaceProjection/contextPressure/contextBreakdown shadow-price 折叠自洽。

## 待办
1. 等 t4(reviewer) 汇总落盘 final-report.md。
2. 据最终报告修复高价值项(SSRF 阻断、PRIVILEGED_METHODS 补两方法、pwsh 镜像 bash 等)。环境 danger-full-access、approval disabled。
