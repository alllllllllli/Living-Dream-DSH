#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CNB CodeBuddy NPC -> OpenAI-compatible proxy
将 CNB Issue 里的 @CodeBuddy NPC 调用封装成标准 /v1/chat/completions 接口,
供 dsh / Cherry Studio 等 OpenAI 兼容客户端挂载。

用法:
  python cnb_proxy.py [port]     # 默认 8800
配置:
  CNB_API_KEY  环境变量、--token 参数或 ~/.dsh/.credentials.yaml
  仓库路径     --repo 参数 > CNB_REPO 环境变量 > ~/.dsh/.credentials.yaml(CNB_REPO 行)
              仓库必须是私有仓库(接口的 invisible 参数实际不生效, 靠私有兜底)
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
PLACEHOLDER_REPO = "your-org/your-repo"
POLL_INTERVAL = 5
MAX_WAIT = 180  # 秒
STABLE_POLLS = 2  # 连续 N 次轮询评论无变化, 视为 NPC 写完
MENTION_RE = re.compile(r"^@[\w./\-()（）]+(\([^)]*\))?[\s:：]*")

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


def fetch_all_comments(repo, number, token):
    """拉取 Issue 全部评论 (分页, 每页 100 条)."""
    comments, page = [], 1
    while page <= 10:  # ponytail: 上限 10 页, 正常对话远达不到
        st, batch = http_call(
            "GET",
            f"{CNB_HOST}/{repo}/-/issues/{number}/comments?page={page}&per_page=100",
            token=token,
        )
        if not isinstance(batch, list) or not batch:
            break
        comments.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return comments


def close_issue(repo, number, token):
    """回复拿到后尽力关闭 Issue, 避免仓库堆积垃圾; 失败静默."""
    try:
        http_call("PUT", f"{CNB_HOST}/{repo}/-/issues/{number}", {"state": "closed"}, token)
    except Exception:
        pass


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
    seen_sig = None      # 最后一条 NPC 评论的 (id, 正文长度) 签名
    stable = 0
    reply_body = ""
    while time.time() < deadline:
        time.sleep(POLL_INTERVAL)
        comments = fetch_all_comments(repo, number, token)
        npc_replies = [c for c in comments if c.get("author", {}).get("is_npc")]
        if npc_replies:
            latest = npc_replies[-1]
            body = MENTION_RE.sub("", latest.get("body", "") or "").strip()
            sig = (latest.get("id"), len(body))
            if body:
                reply_body = body
            # ponytail: CNB 没有"回复完成"标志, 用稳定性启发式 —
            # 评论 id+长度连续 STABLE_POLLS 次(10s)不变视为写完.
            # 边写边改超过 10s 停顿的极长回复会被提前截断, 可调大 STABLE_POLLS.
            stable = stable + 1 if sig == seen_sig and sig is not None else 0
            seen_sig = sig
            if stable >= STABLE_POLLS and reply_body:
                close_issue(repo, number, token)
                return reply_body, None
    if reply_body:
        close_issue(repo, number, token)
        return reply_body, None
    close_issue(repo, number, token)
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
            # 上游是整段回复, 切成小块真流式发送 (每块 16 字符, 20ms 间隔)
            pieces = [reply[i:i + 16] for i in range(0, len(reply), 16)] or [""]
            for i, piece in enumerate(pieces):
                delta = {"role": "assistant"} if i == 0 else {}
                delta["content"] = piece
                self._send_sse([
                    {"id": "chatcmpl-cnb", "object": "chat.completion.chunk", "created": created, "model": model,
                     "choices": [{"index": 0, "delta": delta, "finish_reason": None}]},
                ])
                time.sleep(0.02)
            self._send_sse([
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


def read_cred(key):
    """从 ~/.dsh/.credentials.yaml 读取指定 Key 行的值, 缺省返回空串."""
    try:
        path = os.path.join(os.path.expanduser("~"), ".dsh", ".credentials.yaml")
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith(key + ":"):
                        return line.split(":", 1)[1].strip().strip('"').strip("'")
    except Exception:
        pass
    return ""


def load_cnb_token():
    """优先从 ~/.dsh/.credentials.yaml 读取 CNB_API_KEY, 其次环境变量."""
    return read_cred("CNB_API_KEY") or os.environ.get("CNB_API_KEY", "")


def load_cnb_repo():
    """优先从 ~/.dsh/.credentials.yaml 读取 CNB_REPO, 其次环境变量."""
    return read_cred("CNB_REPO") or os.environ.get("CNB_REPO", "")


def main():
    global ARGS
    ap = argparse.ArgumentParser(description="CNB NPC OpenAI proxy")
    ap.add_argument("--port", type=int, default=8800)
    ap.add_argument("--repo", default="")
    ap.add_argument("--token", default="")
    ARGS = ap.parse_args()
    ARGS.repo = ARGS.repo or load_cnb_repo()
    if not ARGS.repo or ARGS.repo == PLACEHOLDER_REPO:
        print(
            "[cnb-proxy] 错误: 未配置 CNB 仓库. 请在 ~/.dsh/.credentials.yaml 里写一行 CNB_REPO: your-org/your-repo, "
            "或设置环境变量 CNB_REPO, 或用 --repo 指定. 仓库必须是私有仓库!",
            file=sys.stderr,
        )
        sys.exit(1)
    if not (ARGS.token or load_cnb_token()):
        print("[cnb-proxy] 警告: 未找到 CNB_API_KEY(.credentials.yaml 或环境变量), 请求将失败", file=sys.stderr)
    srv = ThreadingHTTPServer(("127.0.0.1", ARGS.port), Handler)
    print(f"[cnb-proxy] listening on http://127.0.0.1:{ARGS.port}/v1  repo={ARGS.repo}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
