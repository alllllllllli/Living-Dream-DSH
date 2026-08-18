"""dsh-history MCP server — query and search DSH session history.

Tools:
  list_sessions  — list recent sessions (title, time, message count)
  get_session    — read full conversation of a session
  search_history — keyword search across all sessions

DSH stores sessions as ~/.dsh/sessions/<workspace-dir>/session-<id>/session.jsonl.zstd.
Each file is a zstd-compressed JSONL log. The zstd stream is MULTI-FRAME and every
frame has NO content-size header (streaming frames), so it must be decoded with
`stream_reader(read_across_frames=True)` — calling `decompress()` raises
"could not determine content size in frame header".

The JSONL contains one event per line. Relevant events:
  session          — { id, createdAt, cwd }
  session/title    — { data.title }
  user/message     — { data.content[] , data.source.kind }  (kind=="user" is real input)
  assistant/message — { data.message.content[] }
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

from mcp.server.fastmcp import FastMCP

try:
    import zstandard
except ImportError:  # pragma: no cover - surfaced at runtime, not load time
    zstandard = None

mcp = FastMCP("dsh-history")

SESSIONS_DIR = Path.home() / ".dsh" / "sessions"


def _iter_session_files():
    """Yield (session_id, file_path) for every session.jsonl.zstd, newest first."""
    if not SESSIONS_DIR.exists():
        return
    entries = []
    # Recursive: <workspace>/session-<id>/session.jsonl.zstd
    for f in SESSIONS_DIR.rglob("session.jsonl.zstd"):
        sid = f.parent.name  # "session-<uuid>"
        try:
            mtime = f.stat().st_mtime
        except OSError:
            mtime = 0
        entries.append((sid, f, mtime))
    entries.sort(key=lambda e: e[2], reverse=True)
    for sid, fpath, _ in entries:
        yield sid, fpath


def _read_jsonl(session_id: str, path: Path):
    """Decode one session.jsonl.zstd into a list of parsed event dicts (or None)."""
    if zstandard is None:
        return None
    try:
        raw = path.read_bytes()
    except OSError:
        return None
    try:
        dctx = zstandard.ZstdDecompressor()
        out = dctx.stream_reader(raw, read_across_frames=True).read()
    except Exception:
        return None
    lines = out.decode("utf-8", errors="replace").splitlines()
    events = []
    for ln in lines:
        ln = ln.strip()
        if not ln:
            continue
        try:
            events.append(json.loads(ln))
        except Exception:
            continue
    return events


def _title_from(events: list) -> str:
    for e in events:
        if e.get("type") == "session/title":
            t = e.get("data", {}).get("title")
            if t:
                return t
    return ""


def _messages_from(events: list) -> list:
    """Return a normalized list of {role, text} for user/assistant messages."""
    msgs = []
    for e in events:
        t = e.get("type")
        if t == "user/message":
            src = e.get("data", {}).get("source", {})
            # Only real user input; skip plugin/system snapshots.
            if src.get("kind") != "user":
                continue
            content = e.get("data", {}).get("content", [])
            text = _content_text(content)
            if text:
                msgs.append({"role": "user", "text": text})
        elif t == "assistant/message":
            content = e.get("data", {}).get("message", {}).get("content", [])
            text = _content_text(content)
            if text:
                msgs.append({"role": "assistant", "text": text})
    return msgs


def _content_text(content) -> str:
    """Flatten a content array into text (concat text blocks, skip reasoning)."""
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    parts = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            parts.append(str(block.get("text", "")))
    return "\n".join(p for p in parts if p)


@mcp.tool()
def list_sessions(limit: int = 20) -> str:
    """List recent DSH sessions.

    Args:
        limit: Max sessions to return (default 20).

    Returns:
        JSON array of {id, title, time, messages}.
    """
    result = []
    for sid, fpath in _iter_session_files():
        events = _read_jsonl(sid, fpath)
        if not events:
            continue
        msgs = _messages_from(events)
        title = _title_from(events)
        mtime = datetime.fromtimestamp(fpath.stat().st_mtime).isoformat(timespec="seconds")
        result.append({
            "id": sid,
            "title": title or sid,
            "time": mtime,
            "messages": len(msgs),
        })
        if len(result) >= limit:
            break
    return json.dumps(result, ensure_ascii=False, indent=2)


@mcp.tool()
def get_session(session_id: str) -> str:
    """Read the full conversation of a session.

    Args:
        session_id: Session ID ("session-<uuid>").

    Returns:
        JSON with {id, title, messages:[{role,text}]}.
    """
    for sid, fpath in _iter_session_files():
        if sid != session_id:
            continue
        events = _read_jsonl(sid, fpath)
        if not events:
            return json.dumps({"error": f"Failed to decode session: {session_id}"})
        return json.dumps({
            "id": sid,
            "title": _title_from(events) or sid,
            "messages": _messages_from(events),
        }, ensure_ascii=False, indent=2)
    return json.dumps({"error": f"Session not found: {session_id}"})


@mcp.tool()
def search_history(query: str, limit: int = 10) -> str:
    """Search across all sessions by keyword.

    Args:
        query: Keyword to search (case-insensitive, matched against message text).
        limit: Max results to return (default 10).

    Returns:
        JSON array of matching {session_id, title, snippet}.
    """
    query_lower = query.lower()
    results = []
    for sid, fpath in _iter_session_files():
        events = _read_jsonl(sid, fpath)
        if not events:
            continue
        title = _title_from(events)
        for m in _messages_from(events):
            text = m["text"]
            if query_lower in text.lower():
                idx = text.lower().find(query_lower)
                start = max(0, idx - 40)
                end = min(len(text), idx + len(query) + 40)
                snippet = text[start:end].replace("\n", " ")
                results.append({
                    "session_id": sid,
                    "title": title or sid,
                    "snippet": f"...{snippet}...",
                })
                break  # One match per session is enough
        if len(results) >= limit:
            break
    return json.dumps(results, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run(transport="stdio")
