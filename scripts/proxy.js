// DSH Phone Remote Proxy
// Rewrites request headers to bypass DSH Web UI CORS checks.
// Listens on 127.0.0.1:8090, proxies to DSH at 127.0.0.1:3080.
//
// Usage:
//   npm install http-proxy   (one-time)
//   node scripts/proxy.js
//
// Then point Tailscale Serve at the proxy:
//   tailscale serve --https=443 --bg http://127.0.0.1:8090

const http = require('http');
const httpProxy = require('http-proxy');

const DSH_HOST = process.env.DSH_HOST || 'http://127.0.0.1:3080';
const PROXY_PORT = parseInt(process.env.PROXY_PORT || '8090', 10);

const proxy = httpProxy.createProxyServer({
  target: DSH_HOST,
  ws: true
});

proxy.on('error', (err, req, res) => {
  console.error(`[proxy] error: ${err.message}`);
  if (res && !res.headersSent) {
    res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end('Bad Gateway');
  }
});

const server = http.createServer((req, res) => {
  req.headers['host'] = '127.0.0.1:3080';
  req.headers['origin'] = 'http://127.0.0.1:3080';
  req.headers['sec-fetch-site'] = 'same-origin';
  proxy.web(req, res);
});

server.on('upgrade', (req, socket, head) => {
  req.headers['host'] = '127.0.0.1:3080';
  req.headers['origin'] = 'http://127.0.0.1:3080';
  proxy.ws(req, socket, head);
});

server.listen(PROXY_PORT, '127.0.0.1', () => {
  console.log(`[proxy] listening on http://127.0.0.1:${PROXY_PORT} -> ${DSH_HOST}`);
});
