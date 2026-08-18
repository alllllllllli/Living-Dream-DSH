"""dsh-memory MCP server — long-term semantic memory backed by the shared memory-mcp engine.

This is a THIN wrapper over the real memory store used by dsh agents today
(G:/vision-files/memory-mcp/store_engine.py + store/memory.db). It does NOT keep
its own ~/.dsh/memory/entries.json + TF-IDF index — that old design was a separate,
empty store that could not see any accumulated memory. This server reuses the exact
same SQLite DB and retrieval (ANN + BM25 + RRF fusion + time-decay/importance ranking),
so recall/remember land on the SAME memory the user has been building.

Locating the engine:
  - env MEMORY_MCP_DIR -> path to the memory-mcp directory (contains store_engine.py)
  - fallback ORDER: <memory-mcp dir listed in a search path>, then ~/memory-mcp
  - store_engine reads MEMORY_DB env to override the DB path (default <engine>/store/memory.db)

Tools (mirror of the real memory-mcp):
  remember / recall / forget / update_memory / list_memories / recall_facts / list_blocks

Embedding: Ollama bge-m3 (127.0.0.1:11434). recall/remember need Ollama running;
list_memories / list_blocks / forget(by id) / update(by id) are pure SQLite reads/writes
and work without it. Store-side embed comes from store_engine._embed_local.
"""

import json
import os
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dsh-memory")

# 当前绑定的 agent 名（客户端 mcp_server.env 传入 MEMORY_AGENT，如 dsh / 浔）
AGENT_NAME = os.environ.get("MEMORY_AGENT", "").strip() or "未知"

# ---- locate the real memory engine ----------------------------------------
_CANDIDATE_DIRS = []
_env_dir = os.environ.get("MEMORY_MCP_DIR", "").strip()
if _env_dir:
    _CANDIDATE_DIRS.append(_env_dir)
_CANDIDATE_DIRS.append(str(Path.home() / "memory-mcp"))

se = None  # store_engine module, or None if not found


def _find_engine():
    for d in _CANDIDATE_DIRS:
        if not d:
            continue
        p = Path(d)
        if (p / "store_engine.py").exists():
            return p
    return None


_engine_dir = _find_engine()
if _engine_dir:
    sys.path.insert(0, str(_engine_dir))
    try:
        import store_engine as se
    except Exception:
        se = None


def _engine_error(action):
    if se is None:
        hint = "未找到记忆引擎。请设置 MEMORY_MCP_DIR 指向 memory-mcp 目录（含 store_engine.py）。"
        return {"error": f"{action}失败：{hint}"}
    return None


# bge-m3 检索指令前缀：查询侧加、存储侧不加（非对称指令检索，与 memory-mcp 一致）
QUERY_INSTRUCTION = "Represent this sentence for searching relevant passages:"


def _embed(text, as_query=False):
    """Embed text via store_engine (Ollama bge-m3). Raises on failure."""
    if as_query:
        text = QUERY_INSTRUCTION + " " + text
    return se._embed_local(text)


def _fmt_hit(h):
    return {
        "id": h["id"],
        "text": h["text"],
        "source": h.get("source", ""),
        "ts": h.get("ts", ""),
        "score": round(h.get("score", 0.0), 4),
        "block": h.get("block", "general"),
        "kind": h.get("kind", "semantic"),
        "importance": h.get("importance", 0.5),
    }


@mcp.tool()
def remember(content: str, block: str = "general", importance: float = 0.5,
             kind: str = "semantic") -> str:
    """Store a memory into the shared memory DB (Mem0-style conflict handling).

    Args:
        content: Text to remember (1-3 sentences with key facts/preferences).
        block: Named memory block (Letta-style namespace). Default "general".
        importance: 0-1, higher ranks first in recall. Default 0.5.
        kind: semantic | episodic | procedural. Default semantic.
    """
    err = _engine_error("写入")
    if err:
        return json.dumps(err, ensure_ascii=False)
    content = (content or "").strip()
    if not content:
        return json.dumps({"error": "内容为空"}, ensure_ascii=False)
    if kind not in ("semantic", "episodic", "procedural"):
        kind = "semantic"
    importance = max(0.0, min(1.0, float(importance or 0.5)))
    try:
        vec = _embed(content)
        r = se.add_entry(content, AGENT_NAME, vec, conflict=True, block=block,
                         importance=importance, kind=kind, origin="manual",
                         extract_facts=True)
    except Exception as e:
        return json.dumps({"error": f"写入失败: {e}"}, ensure_ascii=False)
    return json.dumps(r, ensure_ascii=False, indent=2)


@mcp.tool()
def recall(query: str, top_k: int = 5, scope: str = "all", block: str = "") -> str:
    """Semantic search over the shared memory DB.

    Args:
        query: Natural language question (e.g. "用户喜欢用什么播放器？").
        top_k: Number of results (default 5).
        scope: "all" = shared memory (default); "mine" = only current agent.
        block: Restrict to one memory block (empty = all).
    """
    err = _engine_error("检索")
    if err:
        return json.dumps(err, ensure_ascii=False)
    query = (query or "").strip()
    if not query:
        return json.dumps({"error": "检索词为空"}, ensure_ascii=False)
    try:
        qvec = _embed(query, as_query=True)
        hits = se.search(qvec, query, top_k=top_k,
                         scope=(None if scope == "all" else AGENT_NAME),
                         block=(block or None))
    except Exception as e:
        return json.dumps({"error": f"检索失败（embedding 不可用，请确认 Ollama 已启动且有 bge-m3）: {e}"}, ensure_ascii=False)
    if not hits:
        return json.dumps([], ensure_ascii=False)
    return json.dumps([_fmt_hit(h) for h in hits], ensure_ascii=False, indent=2)


@mcp.tool()
def forget(entry_id: int = 0, query: str = "") -> str:
    """Soft-delete a memory (history preserved).

    Args:
        entry_id: Exact entry id (from list_memories/recall).
        query: Alternatively, delete the best semantic match (one of entry_id/query).
    """
    err = _engine_error("删除")
    if err:
        return json.dumps(err, ensure_ascii=False)
    if entry_id:
        r = se.soft_delete(int(entry_id), source_hint=AGENT_NAME)
        return json.dumps(r, ensure_ascii=False, indent=2)
    if query:
        try:
            qvec = _embed(query, as_query=True)
            best = se.find_best_match(qvec, query, min_score=0.55)
            if best:
                r = se.soft_delete(best["id"], source_hint=AGENT_NAME)
                if r.get("action") == "deleted":
                    return json.dumps(r, ensure_ascii=False, indent=2)
            return json.dumps({"error": f"没有高置信匹配「{query}」，请用 entry_id 精确删除"}, ensure_ascii=False)
        except Exception as e:
            return json.dumps({"error": f"删除失败: {e}"}, ensure_ascii=False)
    return json.dumps({"error": "请提供 entry_id 或 query"}, ensure_ascii=False)


@mcp.tool()
def update_memory(new_content: str, entry_id: int = 0, query: str = "") -> str:
    """Update an existing memory (re-embed, history preserved).

    Args:
        new_content: New text (required).
        entry_id: Exact entry id (optional).
        query: Alternatively, update the best semantic match (optional).
    """
    err = _engine_error("更新")
    if err:
        return json.dumps(err, ensure_ascii=False)
    new_content = (new_content or "").strip()
    if not new_content:
        return json.dumps({"error": "new_content 为空"}, ensure_ascii=False)
    if entry_id:
        r = se.update_entry(int(entry_id), new_content, source_hint=AGENT_NAME)
        return json.dumps(r, ensure_ascii=False, indent=2)
    if query:
        try:
            qvec = _embed(query, as_query=True)
            best = se.find_best_match(qvec, query, min_score=0.5)
            if best:
                r = se.update_entry(best["id"], new_content, source_hint=AGENT_NAME)
                if r.get("action") == "updated":
                    return json.dumps(r, ensure_ascii=False, indent=2)
            return json.dumps({"error": f"没有高置信匹配「{query}」，请用 entry_id 精确更新"}, ensure_ascii=False)
        except Exception as e:
            return json.dumps({"error": f"更新失败: {e}"}, ensure_ascii=False)
    return json.dumps({"error": "请提供 entry_id 或 query"}, ensure_ascii=False)


@mcp.tool()
def list_memories(limit: int = 20, offset: int = 0, scope: str = "all",
                  block: str = "", keyword: str = "") -> str:
    """List memory entries (id descending), filterable.

    Args:
        limit: Max entries (default 20).
        offset: Skip N (default 0).
        scope: "all" (default) or "mine".
        block: Restrict to one block (empty = all).
        keyword: Substring filter on text (empty = none).
    """
    err = _engine_error("列出")
    if err:
        return json.dumps(err, ensure_ascii=False)
    rows = se.list_entries(limit=int(limit), offset=int(offset),
                           scope=(None if scope == "all" else AGENT_NAME),
                           block=(block or None), keyword=(keyword or None))
    return json.dumps(rows, ensure_ascii=False, indent=2)


@mcp.tool()
def recall_facts(query: str, top_k: int = 8) -> str:
    """Search structured facts (entity/attribute/value triples auto-extracted from memory).

    Args:
        query: Keyword/entity/attribute, e.g. "主机系统".
        top_k: Number of facts (default 8).
    """
    err = _engine_error("检索事实")
    if err:
        return json.dumps(err, ensure_ascii=False)
    fs = se.facts_search(query, top_k=top_k)
    return json.dumps(fs, ensure_ascii=False, indent=2)


@mcp.tool()
def list_blocks() -> str:
    """List all memory blocks and their entry counts."""
    err = _engine_error("列出记忆块")
    if err:
        return json.dumps(err, ensure_ascii=False)
    blks = se.list_blocks()
    return json.dumps([{"block": b, "count": n} for b, n in blks], ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run(transport="stdio")
