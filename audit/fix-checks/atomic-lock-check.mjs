// atomic-lock-check.mjs — runnable check：验证 dsh-atomic-write 的 withFileLock
// ① 不再 ReferenceError（writeFile 已补 import）；② 能原子回收孤儿锁（死 PID 的 .lock）。
import { spawn } from 'node:child_process'
import { mkdtemp, writeFile, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

const { withFileLock } = await import(
  pathToFileURL('<dsh-install>/node_modules/@deepseek-ai/dsh-atomic-write/lib/index.js').href
)

const dir = await mkdtemp(join(tmpdir(), 'atomic-lock-check-'))
const target = join(dir, 'data.txt')

// 拿到一个已退出的死 PID
const child = spawn(process.execPath, ['-e', 'setTimeout(()=>{}, 10000)'])
const deadPid = child.pid
child.kill()
await new Promise((resolve) => child.on('exit', resolve))

// 写孤儿锁（死 PID 持有者）
await writeFile(`${target}.lock`, `${deadPid}\n`, { flag: 'wx' })

// withFileLock 应回收孤儿锁并成功执行 operation
let ran = false
const result = await withFileLock(target, async () => { ran = true; return 'ok' })
if (result !== 'ok' || !ran) throw new Error('withFileLock did not run operation after reclaim')

// 锁应已释放（operation 的 finally rm）
let lockGone = false
try { await readFile(`${target}.lock`) } catch (e) { if (e.code === 'ENOENT') lockGone = true }

await rm(dir, { recursive: true, force: true })
if (!lockGone) throw new Error('lock still present after operation')
console.log('atomic-lock-check: PASS (no ReferenceError + reclaimed orphan lock + released)')
