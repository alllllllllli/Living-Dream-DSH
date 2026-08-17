"""dsh-memory MCP server — long-term semantic memory for DSH agents.

Tools:
  remember      — store a memory entry with metadata
  recall        — semantic search across memories
  forget        — delete a memory by id
  list_memories — list all stored memories

Storage: ~/.dsh/memory/entries.json (auto-created).
Search: TF-IDF cosine similarity (stdlib only, no external deps).
"""

import json
import math
import os
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dsh-memory")

MEMORY_DIR = Path.home() / ".dsh" / "memory"
ENTRIES_FILE = MEMORY_DIR / "entries.json"


def _ensure_dir():
    MEMORY_DIR.mkdir(parents=True, exist_ok=True)


def _load_entries() -> list:
    if ENTRIES_FILE.exists():
        try:
            return json.loads(ENTRIES_FILE.read_text(encoding="utf-8"))
        except Exception:
            return []
    return []


def _save_entries(entries: list):
    _ensure_dir()
    ENTRIES_FILE.write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding="utf-8")


def _tokenize(text: str) -> list:
    """Simple word/char tokenizer for CJK + Latin."""
    # Split on whitespace and punctuation, keep CJK chars as individual tokens
    tokens = re.findall(r"[\w\u4e00-\u9fff]+", text.lower())
    return tokens


def _tf(tokens: list) -> dict:
    """Term frequency."""
    counts = Counter(tokens)
    total = len(tokens)
    if total == 0:
        return {}
    return {t: c / total for t, c in counts.items()}


def _cosine_sim(a: dict, b: dict) -> float:
    """Cosine similarity between two sparse vectors."""
    keys = set(a) & set(b)
    if not keys:
        return 0.0
    dot = sum(a[k] * b[k] for k in keys)
    norm_a = math.sqrt(sum(v * v for v in a.values()))
    norm_b = math.sqrt(sum(v * v for v in b.values()))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


@mcp.tool()
def remember(content: str, tags: str = "") -> str:
    """Store a new memory entry.

    Args:
        content: The text to remember.
        tags: Optional comma-separated tags (e.g. "preference,code").

    Returns:
        Confirmation with the new entry's id.
    """
    entries = _load_entries()
    entry_id = max((e.get("id", 0) for e in entries), default=0) + 1
    entry = {
        "id": entry_id,
        "content": content,
        "tags": [t.strip() for t in tags.split(",") if t.strip()],
        "created": datetime.now().isoformat(timespec="seconds"),
    }
    entries.append(entry)
    _save_entries(entries)
    return json.dumps({"ok": True, "id": entry_id, "total": len(entries)})


@mcp.tool()
def recall(query: str, top_k: int = 5) -> str:
    """Search memories by semantic similarity.

    Args:
        query: Natural language query.
        top_k: Number of top results to return (default 5).

    Returns:
        JSON array of matching memories with similarity scores.
    """
    entries = _load_entries()
    if not entries:
        return json.dumps([])

    query_tf = _tf(_tokenize(query))
    scored = []
    for e in entries:
        entry_tf = _tf(_tokenize(e.get("content", "")))
        sim = _cosine_sim(query_tf, entry_tf)
        scored.append((sim, e))
    scored.sort(key=lambda x: x[0], reverse=True)

    results = []
    for sim, e in scored[:top_k]:
        if sim > 0:
            results.append({
                "id": e["id"],
                "content": e["content"],
                "tags": e.get("tags", []),
                "score": round(sim, 4),
                "created": e.get("created", ""),
            })
    return json.dumps(results, ensure_ascii=False, indent=2)


@mcp.tool()
def forget(entry_id: int) -> str:
    """Delete a memory by its id.

    Args:
        entry_id: The id of the memory to delete.

    Returns:
        Confirmation.
    """
    entries = _load_entries()
    before = len(entries)
    entries = [e for e in entries if e.get("id") != entry_id]
    if len(entries) == before:
        return json.dumps({"error": f"Entry {entry_id} not found"})
    _save_entries(entries)
    return json.dumps({"ok": True, "deleted": entry_id, "remaining": len(entries)})


@mcp.tool()
def list_memories(limit: int = 50) -> str:
    """List all stored memories.

    Args:
        limit: Max entries to return (default 50).

    Returns:
        JSON array of memory entries.
    """
    entries = _load_entries()
    return json.dumps(entries[-limit:], ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run(transport="stdio")
