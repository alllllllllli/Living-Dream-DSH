import { HttpFetchProvider } from "file:///D:/Tools/DeepSeekHarness-Desktop/resources/dsh-runtime/node_modules/@deepseek-ai/dsh-web-fetch-http/lib/index.js";

const p = new HttpFetchProvider({ maxUrlLength: 2048, maxResponseBytes: 1000, maxBodyChars: 1000, timeoutMs: 5000, maxRedirects: 0, userAgent: "t" });

const urls = [
	"http://127.0.0.1:3080/",
	"http://10.0.0.1/",
	"http://172.16.0.1/",
	"http://192.168.1.1/",
	"http://169.254.169.254/latest/meta-data/",
	"http://[::1]/",
	"http://[::ffff:127.0.0.1]/",
	"http://0.0.0.0/",
	"http://localhost/",
	"http://foo.internal/",
	"http://foo.localhost/"
];

let failures = 0;
for (const url of urls) {
	try {
		await p.fetch({ url });
		console.log(`FAIL ${url} — not blocked`);
		failures++;
	} catch (e) {
		if (e?.code === "WEB_BLOCKED_URL") {
			console.log(`PASS ${url} — ${e.code}`);
		} else {
			console.log(`FAIL ${url} — threw ${e?.code ?? "non-WebError"}: ${e?.message}`);
			failures++;
		}
	}
}

if (failures === 0) {
	console.log("ALL PASS");
	process.exit(0);
} else {
	console.log(`${failures} FAIL`);
	process.exit(1);
}
