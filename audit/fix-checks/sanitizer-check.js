import assert from 'node:assert/strict'
import { sanitizeUploadName } from './index.js'

const cases = [
  ['.env', '.env'],
  ['.gitignore', '.gitignore'],
  ['CON', '_CON'],
  ['con', '_con'],
  ['nul.txt', '_nul.txt'],
  ['com1', '_com1'],
  ['LPT1.log', '_LPT1.log'],
  ['foo.', 'foo_'],
  ['foo ', 'foo'],
  ['report.txt', 'report.txt'],
  ['.upload-secret', 'file-.upload-secret'],
  ['../../报告.txt', '报告.txt'],
  ['', 'upload.bin'],
]

for (const [input, expected] of cases) {
  const actual = sanitizeUploadName(input)
  assert.equal(actual, expected, `sanitizeUploadName(${JSON.stringify(input)}) => ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)}`)
  console.log(`ok  ${JSON.stringify(input)} -> ${JSON.stringify(actual)}`)
}

console.log(`\n${cases.length} sanitizer cases passed`)
