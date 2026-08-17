#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CNB CodeBuddy NPC -> OpenAI-compatible proxy
将 CNB Issue 里的 @CodeBuddy NPC 调用封装成标准 /v1/chat/completions 接口,
供 dsh / Cherry Studio 等 OpenAI 兼容客户端挂载。

用法:
  python cnb_proxy.py [port]     # 默认 8800
配置:
  CNB_API_KEY  环境变量或 --token 参数(CNB 访问令牌)
  仓库路径     通过 --repo 指定, 默认 CNB_REPO 环境变量或 your-org/your-repo
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CNB_HOST = "https://api.cnb.cool"
MODEL_MAP = {
    "deepseek-v4-flash": "@npc/CodeBuddy",
    "deepseek-v4-pro": "@npc/CodeBuddy(deepseek-v4-pro)",
}
DEFAULT_REPO = os.environ.get("CNB_REPO", "your-org/your-repo")
POLL_INTERVAL = 5
MAX_WAIT = 180  # 秒

ARGS = None


def http_call(method, url, data=None, token=None, accept="application/vnd.cnb.api+json"):
    headers = {"Authorization": "Bearer " + token, "Accept": accept}
    body = None
    if data is not None:
        body = json.dumps(data).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            raw = r.read().decode("utf-8", "replace")
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")[:400]
    except Exception as e:
        return -1, str(e)[:200]


def build_issue_body(model, messages):
    """把 OpenAI messages 拼成 CNB Issue 正文, 并在最前面 @ 对应 NPC."""
    npc = MODEL_MAP.get(model, MODEL_MAP["deepseek-v4-flash"])
    lines = [npc + " 请执行以下对话任务, 逐条回答用户消息."]
    for m in messages:
        role = m.get("role", "user")
        content = m.get("content", "")
        if isinstance(content, list):  # 多模态 content, 只取文本
            content = " ".join(
                p.get("text", "") for p in content if isinstance(p, dict) and p.get("type") == "text"
            )
        content = str(content).strip()
        if not content:
            continue
        if role == "user":
            lines.append("用户: " + content)
        elif role == "assistant":
            lines.append("助手: " + content)
        else:
            lines.append("用户: " + content)
    return "\n".join(lines)


def call_npc(model, messages, token, repo):
    title = "dsh-" + str(int(time.time()))
    st, r = http_call(
        "POST",
        f"{CNB_HOST}/{repo}/-/issues",
        {"title": title, "body": build_issue_body(model, messages), "work_mode": True, "invisible": True},
        token,
    )
    if st not in (200, 201) or not isinstance(r, dict):
        return None, f"创建 Issue 失败: {st} {r}"
    number = r.get("number")
    if not number:
        return None, "Issue 创建响应缺少 number"

    deadline = time.time() + MAX_WAIT
    last_len = 0
    while time.time() < deadline:
        time.sleep(POLL_INTERVAL)
        st, comments = http_call(
            "GET", f"{CNB_HOST}/{repo}/-/issues/{number}/comments", token=token
        )
        if not isinstance(comments, list):
            continue
        # 找 is_npc 的新回复 (去重, 只看新增的)
        npc_replies = [c for c in comments if c.get("author", {}).get("is_npc")]
        if len(npc_replies) > last_len:
            last_len = len(npc_replies)
            latest = npc_replies[-1]
            body = latest.get("body", "") or ""
            # 去掉开头的 @提及
            body = re.sub(r"^@[\w.\-()（）]+\([^)]*\)\s*", "", body).strip()
            if body:
                return body, None
        # 检查 NPC 是否明确结束 (statuses 或 issue 状态)
    return None, f"等待 NPC 回复超时({MAX_WAIT}s)"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send_json(self, code, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_sse(self, chunks):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        for chunk in chunks:
            payload = json.dumps(chunk, ensure_ascii=False).encode("utf-8")
            self.wfile.write(b"data: " + payload + b"\n\n")
            self.wfile.flush()
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()

    def do_GET(self):
        if self.path.rstrip("/").endswith("/models") or self.path == "/v1/models":
            models = [
                {"id": "deepseek-v4-flash", "object": "model", "owned_by": "cnb"},
                {"id": "deepseek-v4-pro", "object": "model", "owned_by": "cnb"},
            ]
            self._send_json(200, {"object": "list", "data": models})
        else:
            self._send_json(404, {"error": {"message": "not found", "type": "invalid_request_error"}})

    def do_POST(self):
        if not self.path.rstrip("/").endswith("/chat/completions"):
            self._send_json(404, {"error": {"message": "not found", "type": "invalid_request_error"}})
            return
        try:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length) if length else b"{}"
            req = json.loads(raw.decode("utf-8", "replace") or "{}")
        except Exception as e:
            self._send_json(400, {"error": {"message": f"bad request: {e}", "type": "invalid_request_error"}})
            return

        model = req.get("model", "deepseek-v4-flash")
        messages = req.get("messages", [])
        stream = bool(req.get("stream", False))
        token = ARGS.token or load_cnb_token()
        if not token:
            self._send_json(500, {"error": {"message": "CNB_API_KEY not set", "type": "server_error"}})
            return

        reply, err = call_npc(model, messages, token, ARGS.repo)
        if err:
            self._send_json(502, {"error": {"message": err, "type": "upstream_error"}})
            return

        created = int(time.time())
        if stream:
            delta = {"role": "assistant", "content": reply}
            self._send_sse([
                {"id": "chatcmpl-cnb", "object": "chat.completion.chunk", "created": created, "model": model,
                 "choices": [{"index": 0, "delta": delta, "finish_reason": None}]},
                {"id": "chatcmpl-cnb", "object": "chat.completion.chunk", "created": created, "model": model,
                 "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}]},
            ])
        else:
            self._send_json(200, {
                "id": "chatcmpl-cnb",
                "object": "chat.completion",
                "created": created,
                "model": model,
                "choices": [{
                    "index": 0,
                    "message": {"role": "assistant", "content": reply},
                    "finish_reason": "stop",
                }],
                "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
            })


def load_cnb_token():
    """优先从 ~/.dsh/.credentials.yaml 读取 CNB_API_KEY, 其次环境变量."""
    try:
        import os
        home = os.path.expanduser("~")
        path = os.path.join(home, ".dsh", ".credentials.yaml")
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("CNB_API_KEY:"):
                        return line.split(":", 1)[1].strip().strip('"').strip("'")
    except Exception:
        pass
    return os.environ.get("CNB_API_KEY", "")


def main():
    global ARGS
    ap = argparse.ArgumentParser(description="CNB NPC OpenAI proxy")
    ap.add_argument("--port", type=int, default=8800)
    ap.add_argument("--repo", default=DEFAULT_REPO)
    ap.add_argument("--token", default="")
    ARGS = ap.parse_args()
    if not (ARGS.token or load_cnb_token()):
        print("[cnb-proxy] 警告: 未找到 CNB_API_KEY(.credentials.yaml 或环境变量), 请求将失败", file=sys.stderr)
    srv = ThreadingHTTPServer(("127.0.0.1", ARGS.port), Handler)
    print(f"[cnb-proxy] listening on http://127.0.0.1:{ARGS.port}/v1  repo={ARGS.repo}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
