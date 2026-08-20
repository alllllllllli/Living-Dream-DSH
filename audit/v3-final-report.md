# 第三轮 DSH 架构审计 — 最终汇总报告

> 生成：reviewer · 团队 dsh-audit-v3 · 汇总 t1(security)/t2(core)/t3(plugins)/t4(llm-tools)
> 脱敏约定（全文适用，正文绝无真实路径/用户名/QQ号/token/密钥）：
> `<workspace>`=用户工作目录 · `<dsh-install>`=DSH 安装目录 · `<vision-config-dir>`=视觉配置专用盘目录 · `<local-vision>`/`<cloud-vision>`=本地/云端视觉服务名
> 代码路径：`@deepseek-ai/<pkg>/lib/...` 的完整前缀为 `<dsh-install>` 下的 node_modules；`<workspace>/<插件>` 为用户目录下插件。

## ① 本轮新发现 Bug（按严重程度）

### HIGH（1）
1. **记忆注入把真实凭据逐字注入系统提示并发给外部 LLM**
   `<workspace>/dsh-memory-inject/lib/memory.js:112-122` + `index.js:42-69`
   根因：renderItems/truncate 仅折行 + 200 字符截断，无 secret 脱敏；getProfile 无条件抓取发布记录、配置等高危记忆块。
   证据：本会话系统提示已注入含真实 GitHub PAT 与代理配置的文本，完整 token 落在 200 字符截断范围内。
   修复：注入前按 secret 正则打码，或从高危块排除凭据字段。

### MEDIUM（5）
2. dsh-guard 后置扫描命中即整体替换工具结果（fail-closed，与 fail-open 哲学矛盾）——`<workspace>/dsh-guard/index.js:128-140`。含密钥样字符串的文件（含误报）整体不可读。修：命中后脱敏透传原内容。
3. dsh-guard 漏检 PKCS#8 加密私钥 `-----BEGIN ENCRYPTED PRIVATE KEY-----`——`index.js:36`。修：加 ENCRYPTED 分支。
4. dsh-guard 漏检 `.env` 无引号赋值（`DATABASE_PASSWORD=...`、`AWS_SECRET_ACCESS_KEY=...`）——`index.js:37-38`。修：增无引号分支 + 扩展字符集。
5. dsh-guard 漏过 `rm -rf /*`、`rm -rf ~/*`、`rm -rf /home`——`index.js:49`。修：去 `$` 锚或匹配 `\/\*?`/`~\/?\*?`。
6. file-uploads clearInFlight 30s 竞态仍在，选中文件可静默丢失——`<workspace>/dsh-file-uploads/client.js:224 vs 236-256`。修：发送终态才 clearInFlight，或超时保留可恢复快照。

### LOW（9）
7. dsh-guard `\biex\b` 误伤 Elixir REPL `iex`——`index.js:51`。修：限 `iex\s*[\(&]` 或按工具分流。
8. dsh-guard `/authorized_keys/` 无锚子串，只读 cat/grep 也被拦——`index.js:50`。修：要求 `>>`/`>` 重定向。
9. dsh-guard edit 只扫 new_string 不扫 old_string，密钥藏在锚点漏过——`index.js:85`。修：两者都扫。
10. paste-input collisionKey 仅 win32 小写，macOS 大小写不敏感 FS 下同名 EEXIST→500——`<dsh-install>/dsh-plugins/dsh-paste-input/lib/index.js:181`。修：darwin 也小写或探测 FS 敏感性。
11. paste-input 400 响应原样返回 ValidationError.message，泄漏 sessionId/内部路径——`index.js:511-513`。修：对外通用文案，详情只进 logger。
12. compaction-basic `compactNow` 把一切失败误分类为 busy，真实 cause 藏在 `.cause`——`@deepseek-ai/dsh-compaction-basic/lib/index.js:926-951`。修：外层 catch 只包装「已有活跃工作」一种情况，遇 ManualCompactionError/AbortError 直接 rethrow。
13. ACP 把 max-tokens 终止覆写成 end_turn，丢失 max_tokens 续写信号——`@deepseek-ai/dsh-acp/lib/index.js:462 vs :216`。修：让 codec 产 `max_tokens`（5% 可能为有意，需实现者确认）。
14. cordis-host-runner 动态 invoke 无超时/AbortSignal，永不 resolve 的 handler 会挂死回合——`@deepseek-ai/dsh-cordis-host-runner/lib/index.js:2123`。修：接受 AbortSignal 并 race。
15. typert-generator renderer quote() 未转义 `\r`/U+2028/U+2029（与 emitter 不一致）——`@deepseek-ai/dsh-typert-generator/lib/types/renderer.js:342-343`（UNCERTAIN，当前经 JSON.stringify 掩盖，latent）。

### UNCERTAIN（2）
16. memory-inject extractUserText 依赖 `message.source?.kind==='user'`，若真实 user 消息无该字段则召回静默失效——`<workspace>/dsh-memory-inject/index.js:30-32`。
17. dsh-guard 若 exec.arguments 以 JSON 字符串传入，write/edit 静默不扫、bash/pwsh 把整串 JSON 当命令扫——`<workspace>/dsh-guard/index.js:80-93`。

### 已知残余（非本轮引入，security 速查）
- 无连接级 socket IP 校验（DNS rebinding 残余，fix-ledger 已标建议项）。
- isBlockedIpv4 未拦 multicast 224/4、reserved 240/4、TEST-NET 192.0.2.0/24 等非路由段——低危，可后续补。

## ② 修复验证结果（前两轮修复未回退）

本轮验证既往修复 19 项，全部完好；另有 1 项 follow-up。

- **安全（2）**：SSRF 阻断 ✓（isBlockedIpv4/v6/Hostname + 私有段/IPv6/metadata 域名 + 解析期阻断）；PRIVILEGED_METHODS ✓（host.listDirectory/createDirectory，loopback 403 钉住）。
- **core（6/6）**：session-stats turns 少计；terminal-bash off-by-one；atomic-write fsync；cordis-host-runner `&&` 优先级；subprocess-local 墓碑 env；subprocess-e2b scrub。
- **LLM/tools（6/6）**：dsh-llm tool-call id 兜底可达；blocks() max-tokens 保留闭合 tool-call 块；dsh-llm-pi-ai 非 LlmError 归 TRANSPORT；dsh-llm-retry Retry-After 钳制；dsh-tool-pwsh resolveWorkdir 镜像 bash；dsh-web-search-deepseek available() 布尔化。
- **插件（5）**：memory-inject FTS5/SQL 注入安全（双引号转义 + 参数化 MATCH）；file-uploads Windows 保留名 + FAT32 硬链接回退 copyFile + `.upload-` 前导点；paste-input 1MB JSON cap 与 maxFiles 不再冲突。
- **follow-up（1）**：Bing RSS 兜底为本地补丁（342 行，未落 node_modules），其自身 available():132-134 仍有恒真 bug——重跑 restore 脚本会重新引入。

## ③ Defer 项重估结论（5 项）

| defer 项 | 结论 |
|---|---|
| atomic-write 孤儿 .lock 永久超时（brick 凭据/设置文件） | **修（P3，原子 rename-reclaim）**：lock 已存 PID，rename 仅一个赢家可消除双写者竞态，brick 永久无自愈值得修 |
| ACP aborted→end_turn | 不修：不可达，纯语义 |
| ACP turn/end 边界误报 cancelled | 不修：仅灾难路径触发 |
| continuable + run_in_background:false 降级 | 不修：产品语义非 bug |
| llm-retry always | 不修：opt-in，有 delay 上限 + signal 兜底 |

## ④ 脱敏要点（上传前必须替换；完整逐行清单见 t1 security 输出）

| 类别 | 替换为 | 位置 / 数量 |
|---|---|---|
| 用户工作目录绝对路径 | `<workspace>` | 48 处 / 45 行，含 16 个 .patch 的 diff header（`a/`、`---`、部分 `+++` 侧） |
| DSH 安装目录绝对路径 | `<dsh-install>` | 37 处（含 2 处正斜杠），16 patch `b/` 侧 + fix-checks 2 个 .mjs |
| 视觉配置专用盘目录 | `<vision-config-dir>` | 2 处 |
| 本地视觉服务名 / 云视觉服务名 | `<local-vision>` / `<cloud-vision>` | 各 2 处 |

- **负结果（0 命中，无需替换但仍须持续防范）**：用户名、QQ号、邮箱、机器名、各类真实 token/密钥（含 GitHub PAT、OpenAI key 等所有常见前缀）、公网 IP、其他盘符。
- **apiKey 字段（16 处）**：均为代码字段名（apiKey/apiKeyEnv/resolveApiKey/hasApiKey/DEFAULT_API_KEY_ENV），无真实密钥值，保留不改。
- **可选保留（非个人身份，队长定夺）**：`127.0.0.1:3080`（DSH 本机 GUI 端口）；git blob hash；备份时间戳；SSRF 测试夹具 IP（127.0.0.1/10.0.0.1/172.16.0.1/192.168.1.1/169.254.169.254/0.0.0.0/::1/::ffff:）。

> ⚠ 关键风险（关联 HIGH#1）：dsh-memory-inject 已把真实 GitHub PAT / 代理配置注入系统提示。本轮 audit/ 文件虽 0 命中真实 token，但该插件 bug 不修，后续任何含系统提示的日志/导出都可能泄漏。**建议：先修 HIGH#1 再上传。**
