// Runnable check for fix #1: LLM tool-call id dead-code fallback.
// Drives the real, exported `BlockAssembler` with a delta-only tool-call
// stream whose deltas carry an empty string id (""), then asserts the final
// assembled toolCallId is NOT the empty string.
//
// Old behavior (bug): `partial.toolCallId = chunk.id` assigned "" unconditionally,
// and `partial.toolCallId ?? CallId(call-0)` does not fire for "" (?? only guards
// null/undefined), so the empty id leaked into the final block.
// New behavior: `if (chunk.id)` mirrors the name guard, so "" is not assigned and
// `undefined ?? CallId(call-0)` === "call-0".

import { pathToFileURL } from "node:url";

const LLM_INDEX = pathToFileURL(
  "D:/Tools/DeepSeekHarness-Desktop/resources/dsh-runtime/node_modules/@deepseek-ai/dsh-llm/lib/index.js"
).href;

const { BlockAssembler } = await import(LLM_INDEX);

function assert(cond, msg) {
  if (!cond) {
    console.error("FAIL:", msg);
    process.exitCode = 1;
    throw new Error(msg);
  }
}

// Semantic demonstration of the two behaviors (documented, not the primary driver).
const oldBugEmptyWins = ("" ?? "call-1") === "";
const newBehaviorFallback = (undefined ?? "call-1") === "call-1";
assert(oldBugEmptyWins === true, "sanity: '' ?? fallback === '' (this is the pre-fix bug)");
assert(newBehaviorFallback === true, "sanity: undefined ?? fallback === fallback");

// Primary driver: delta-only tool-call with empty-string id.
const assembler = new BlockAssembler();
assembler.push({ type: "block-start", index: 0, blockType: "tool-call" });
assembler.push({ type: "tool-call-delta", index: 0, id: "", name: "get_weather", argumentsDelta: '{"city":"SF"}' });
assembler.push({ type: "finish", reason: { kind: "stop" } });

const blocks = assembler.blocks();
const toolCall = blocks.find((b) => b.type === "tool-call");

assert(toolCall !== undefined, "a tool-call block should be assembled from the delta stream");
assert(typeof toolCall.id === "string", "toolCallId must be a string");
assert(toolCall.id !== "", `toolCallId must not be empty; got ${JSON.stringify(toolCall.id)}`);
assert(toolCall.id === "call-0", `toolCallId should fall back to call-0; got ${JSON.stringify(toolCall.id)}`);

console.log("PASS: delta-only empty-id tool-call assembled id =", JSON.stringify(toolCall.id));
console.log("      (empty string id no longer leaks into the final toolCallId)");
