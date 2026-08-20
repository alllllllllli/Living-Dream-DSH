// Mirrors the exact line-counting expressions added to
// dsh-terminal-bash/lib/index.js (BoundedTextBuffer.append + LocalPtySession.read),
// since those symbols aren't exported. Asserts the trailing-newline handling.
function appendCount(value, maxLines) {
	const lines = value.split("\n");
	const count = lines[lines.length - 1] === "" ? lines.length - 1 : lines.length;
	if (count > maxLines) return lines.slice(count - maxLines).join("\n");
	return value;
}
function totalLines(text) {
	const lines = text.split("\n");
	return text.length === 0 ? 0 : (lines[lines.length - 1] === "" ? lines.length - 1 : lines.length);
}
const appendCases = [
	["a\nb\nc\n", 2, "b\nc\n"],
	["a\nb", 1, "b"],
	["a\nb\n", 2, "a\nb\n"],
	["a\nb\n", 1, "b\n"],
	["a\n\n\n", 2, "\n\n"],
];
const totalCases = [
	["a\nb\nc\n", 3],
	["a\nb\nc", 3],
	["a\nb\n", 2],
	["", 0],
	["a\n", 1],
];
let fail = 0;
for (const [input, maxLines, expected] of appendCases) {
	const got = appendCount(input, maxLines);
	if (got !== expected) { console.log(`FAIL append(${JSON.stringify(input)}, ${maxLines}) => ${JSON.stringify(got)}, want ${JSON.stringify(expected)}`); fail++; }
}
for (const [text, expected] of totalCases) {
	const got = totalLines(text);
	if (got !== expected) { console.log(`FAIL totalLines(${JSON.stringify(text)}) => ${got}, want ${expected}`); fail++; }
}
console.log(fail === 0 ? "ALL PASS" : `${fail} FAIL`);
process.exit(fail === 0 ? 0 : 1);
