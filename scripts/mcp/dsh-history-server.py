"""dsh-history MCP server — query and search DSH session history.

Tools:
  list_sessions  — list recent sessions (title, time, message count)
  get_session    — read full conversation of a session
  search_history — keyword search across all sessions

DSH stores sessions in ~/.dsh/sessions/ as JSON files.
"""

import json
import os
import sys
from pathlib import Path
from datetime import datetime

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dsh-history")

SESSIONS_DIR = Path.home() / ".dsh" / "sessions"


def _list_session_files():
    """Return session JSON files sorted by mtime descending."""
    if not SESSIONS_DIR.exists():
        return []
    files = list(SESSIONS_DIR.glob("*.json"))
    files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
    return files


def _load_session(path: Path):
    """Load a session JSON, return parsed dict or None."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def _extract_title(data: dict, fallback: str) -> str:
    """Extract a human-readable title from session data."""
    # DSH session format: {title, messages, ...} or {name, ...}
    for key in ("title", "name", "label"):
        if key in data and data[key]:
            return str(data[key])
    # Fall back to first user message snippet
    msgs = data.get("messages", data.get("turns", []))
    if msgs:
        for m in msgs:
            content = m.get("content", "") if isinstance(m, dict) else ""
            if content:
                return content[:80].replace("\n", " ")
    return fallback


def _extract_messages(data: dict) -> list:
    """Extract message list from various DSH session formats."""
    for key in ("messages", "turns", "conversation"):
        if key in data and isinstance(data[key], list):
            return data[key]
    return []


@mcp.tool()
def list_sessions(limit: int = 20) -> str:
    """List recent DSH sessions.

    Args:
        limit: Max sessions to return (default 20).

    Returns:
        JSON array of {id, title, time, messages}.
    """
    files = _list_session_files()[:limit]
    result = []
    for f in files:
        data = _load_session(f)
        if data is None:
            continue
        msgs = _extract_messages(data)
        mtime = datetime.fromtimestamp(f.stat().st_mtime).isoformat(timespec="seconds")
        result.append({
            "id": f.stem,
            "title": _extract_title(data, f.stem),
            "time": mtime,
            "messages": len(msgs),
        })
    return json.dumps(result, ensure_ascii=False, indent=2)


@mcp.tool()
def get_session(session_id: str) -> str:
    """Read the full conversation of a session.

    Args:
        session_id: Session ID (filename without .json).

    Returns:
        JSON of the session data.
    """
    path = SESSIONS_DIR / f"{session_id}.json"
    if not path.exists():
        return json.dumps({"error": f"Session not found: {session_id}"})
    data = _load_session(path)
    if data is None:
        return json.dumps({"error": f"Failed to parse session: {session_id}"})
    return json.dumps(data, ensure_ascii=False, indent=2)


@mcp.tool()
def search_history(query: str, limit: int = 10) -> str:
    """Search across all sessions by keyword.

    Args:
        query: Keyword to search (case-insensitive, matched against message content).
        limit: Max results to return (default 10).

    Returns:
        JSON array of matching {session_id, title, snippet}.
    """
    query_lower = query.lower()
    results = []
    for f in _list_session_files():
        data = _load_session(f)
        if data is None:
            continue
        msgs = _extract_messages(data)
        for m in msgs:
            content = m.get("content", "") if isinstance(m, dict) else ""
            if query_lower in content.lower():
                # Find the match position and extract snippet
                idx = content.lower().find(query_lower)
                start = max(0, idx - 40)
                end = min(len(content), idx + len(query) + 40)
                snippet = content[start:end].replace("\n", " ")
                results.append({
                    "session_id": f.stem,
                    "title": _extract_title(data, f.stem),
                    "snippet": f"...{snippet}...",
                })
                break  # One match per session is enough
        if len(results) >= limit:
            break
    return json.dumps(results, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run(transport="stdio")
