# -*- coding: utf-8 -*-
"""
Memory Store Engine v2 — sqlite 版共享记忆引擎（2026-08-15 v2 升级）

v2 相对 v1 的升级：
  - 向量检索：sqlite-vec (vec0) ANN 替代全量暴力余弦（不可用时自动回退暴力路径）
  - 写入：修复 update/merge 后向量不重嵌的 bug（更新文本时同步重算向量）
  - 新列：deleted(软删除) / block(记忆块, Letta 式) / importance(重要性) /
          kind(语义/情景/过程) / origin(来源通道) / superseded_by(矛盾失效) /
          consolidated_into(反思固化)
  - 历史表 entry_history：update/merge/delete/supersede/consolidate 全部留痕（Anthropic 式版本化）
  - 事实表 facts：轻量知识图谱三元组 (entity, attribute, value)，MCP memory server 思路
  - 检索排序：RRF 融合 + 时间衰减(近因) + 重要性权重 + 可选精排（Ollama rerank 或本地 fastembed 服务）
  - 冲突处理新增 supersede 动作：新记忆推翻旧记忆时旧条目标记过时（Graphiti 式事实失效）
  - 所有表结构变更在 connect() 内自动迁移（meta 表记录 schema_version）

接口兼容旧版：add_entry / search / count / list_texts / dedup / migrate_from_json 签名不变
（仅新增可选 kwargs）。
"""
import json
import os
import re
import sqlite3
import struct
import subprocess
import sys
import time
import urllib.request
import urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
# 支持环境变量覆盖（测试用）：MEMORY_DB 指向临时库
DB = os.environ.get("MEMORY_DB") or os.path.join(HERE, "store", "memory.db")
OLD_JSON = os.path.join(HERE, "store", "memory.json")
OLLAMA = "http://127.0.0.1:11434"
EMBED_MODEL = "bge-m3"
CONFLICT_MODEL = "qwen3-14b"       # 冲突处理/事实抽取/固化用本地模型，免费
RERANK_MODEL = "bge-reranker-v2-m3"
DUP_THRESHOLD = 0.90               # 守护进程/迁移去重阈值
CONFLICT_THRESHOLD = 0.85          # 冲突处理召回阈值（0.85~0.90 边缘相似交 LLM 判断）
VEC_MIN_SCORE = 0.25               # recall 结果过滤阈值（与旧版一致）
RRF_K = 60                         # RRF 融合常数
RECENCY_HALFLIFE_DAYS = 180.0      # 近因衰减半衰期（天）：180 天权重减半
SCHEMA_VERSION = "2"

# 本地 rerank 服务（py3.13 venv + fastembed bge-reranker-v2-m3，Ollama 不支持时使用）
RERANK_LOCAL_URL = "http://127.0.0.1:11511"
RERANK_SERVICE_PY = os.path.join(HERE, "rerank_service.py")
RERANK_VENV_PY = os.path.join(HERE, "rerank_venv", "Scripts", "python.exe")

try:
    import numpy as _np
except Exception:
    _np = None

try:
    import sqlite_vec as _sqlite_vec
except Exception:
    _sqlite_vec = None

# vec 扩展可加载性（进程级；sqlite3.Connection 不支持挂属性/弱引用，用模块级缓存）
_VEC_GLOBAL = None  # None=未探测, True/False=可/不可加载


def _has_vec(conn):
    return _VEC_GLOBAL is True


def log(*args):
    try:
        print("[store_engine]", *args, file=sys.stderr, flush=True)
    except Exception:
        pass


# ---------------- 向量工具 ----------------

def _vec_to_blob(v):
    if _np is not None:
        return _np.asarray(v, dtype="<f4").tobytes()
    return struct.pack("<%df" % len(v), *[float(x) for x in v])


def _blob_vec(b):
    if _np is not None:
        return _np.frombuffer(b, dtype="<f4")
    return struct.unpack("<%df" % (len(b) // 4), b)


def _cosine_batch(qblob, blobs):
    """批量余弦。返回与 blobs 等长的分数列表。"""
    if not blobs:
        return []
    if _np is not None:
        q = _np.frombuffer(qblob, dtype="<f4")
        qn = float(_np.linalg.norm(q))
        dim = len(q)
        try:
            V = _np.frombuffer(b"".join(blobs), dtype="<f4").reshape(len(blobs), dim)
        except Exception:
            return [_cosine_pair(qblob, b) for b in blobs]
        dots = V @ q
        norms = _np.linalg.norm(V, axis=1) * qn + 1e-9
        return (dots / norms).tolist()
    return [_cosine_pair(qblob, b) for b in blobs]


def _cosine_pair(a, b):
    if _np is not None:
        va = _np.frombuffer(a, dtype="<f4")
        vb = _np.frombuffer(b, dtype="<f4")
        return float(va @ vb / (_np.linalg.norm(va) * _np.linalg.norm(vb) + 1e-9))
    va = struct.unpack("<%df" % (len(a) // 4), a)
    vb = struct.unpack("<%df" % (len(b) // 4), b)
    dot = sum(x * y for x, y in zip(va, vb))
    na = sum(x * x for x in va) ** 0.5
    nb = sum(y * y for y in vb) ** 0.5
    return dot / (na * nb) if na and nb else 0.0


def _embed_local(text, timeout=180):
    """引擎内嵌 embedding（Ollama bge-m3）。用于 update/merge/固化时重算新文本向量。"""
    payload = {"model": EMBED_MODEL, "input": text}
    req = urllib.request.Request(
        OLLAMA + "/api/embed",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return data["embeddings"][0]


def _chat_local(messages, timeout=300, fmt="json", temperature=0):
    """调本地 Ollama qwen3-14b 对话。返回 content 字符串；失败抛异常。"""
    payload = {
        "model": CONFLICT_MODEL,
        "messages": messages,
        "stream": False,
        "format": fmt,
        "options": {"temperature": temperature},
    }
    req = urllib.request.Request(
        OLLAMA + "/api/chat",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return (data.get("message") or {}).get("content", "")


# ---------------- 连接 / 迁移 ----------------

SCHEMA = """
CREATE TABLE IF NOT EXISTS entries(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  text TEXT NOT NULL,
  vec BLOB NOT NULL,
  source TEXT NOT NULL DEFAULT '未知',
  ts TEXT NOT NULL,
  created_ms INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  block TEXT NOT NULL DEFAULT 'general',
  importance REAL NOT NULL DEFAULT 0.5,
  kind TEXT NOT NULL DEFAULT 'semantic',
  origin TEXT NOT NULL DEFAULT '',
  superseded_by INTEGER NOT NULL DEFAULT 0,
  consolidated_into INTEGER NOT NULL DEFAULT 0
);
CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(text, tokenize='trigram');
CREATE TABLE IF NOT EXISTS entry_history(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  ts TEXT NOT NULL,
  action TEXT NOT NULL,
  old_text TEXT,
  new_text TEXT,
  source TEXT
);
CREATE TABLE IF NOT EXISTS facts(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL,
  entity TEXT NOT NULL,
  attribute TEXT NOT NULL,
  value TEXT NOT NULL,
  ts TEXT NOT NULL
);
CREATE VIRTUAL TABLE IF NOT EXISTS facts_fts USING fts5(content, tokenize='trigram');
CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);
DROP TRIGGER IF EXISTS entries_ai;
DROP TRIGGER IF EXISTS entries_ad;
DROP TRIGGER IF EXISTS entries_au;
CREATE TRIGGER entries_ai AFTER INSERT ON entries BEGIN
  INSERT INTO entries_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER entries_ad AFTER DELETE ON entries BEGIN
  DELETE FROM entries_fts WHERE rowid = old.id;
END;
CREATE TRIGGER entries_au AFTER UPDATE ON entries BEGIN
  DELETE FROM entries_fts WHERE rowid = old.id;
  INSERT INTO entries_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER IF NOT EXISTS facts_ai AFTER INSERT ON facts BEGIN
  INSERT INTO facts_fts(rowid, content) VALUES (new.id, new.entity || ' ' || new.attribute || ' ' || new.value);
END;
CREATE TRIGGER IF NOT EXISTS facts_ad AFTER DELETE ON facts BEGIN
  DELETE FROM facts_fts WHERE rowid = old.id;
END;
CREATE INDEX IF NOT EXISTS idx_entries_source ON entries(source);
CREATE INDEX IF NOT EXISTS idx_entries_active ON entries(deleted, superseded_by, consolidated_into);
"""

VEC_SCHEMA = """
CREATE VIRTUAL TABLE IF NOT EXISTS vec_entries USING vec0(
  entry_id INTEGER PRIMARY KEY,
  vec float[1024] distance_metric=cosine,
  source TEXT, deleted INTEGER, block TEXT, hidden INTEGER
);
"""


def _ensure_columns(conn):
    """为旧库补齐 v2 新列（幂等）。"""
    cols = {r[1] for r in conn.execute("PRAGMA table_info(entries)").fetchall()}
    for name, ddl in [
        ("deleted", "INTEGER NOT NULL DEFAULT 0"),
        ("block", "TEXT NOT NULL DEFAULT 'general'"),
        ("importance", "REAL NOT NULL DEFAULT 0.5"),
        ("kind", "TEXT NOT NULL DEFAULT 'semantic'"),
        ("origin", "TEXT NOT NULL DEFAULT ''"),
        ("superseded_by", "INTEGER NOT NULL DEFAULT 0"),
        ("consolidated_into", "INTEGER NOT NULL DEFAULT 0"),
    ]:
        if name not in cols:
            conn.execute("ALTER TABLE entries ADD COLUMN %s %s" % (name, ddl))


def _vec_enable(conn):
    """尝试加载 sqlite-vec 扩展；成功返回 True。结果缓存在进程级变量。"""
    global _VEC_GLOBAL
    if _VEC_GLOBAL is False:
        return False
    ok = False
    if _sqlite_vec is not None:
        try:
            conn.enable_load_extension(True)
            conn.load_extension(_sqlite_vec.loadable_path())
            conn.execute(VEC_SCHEMA)
            ok = True
        except Exception as e:
            log("sqlite-vec load failed, fallback brute-force:", e)
    _VEC_GLOBAL = ok
    return ok


def _vec_sync(conn, entry_id, blob=None, source="", deleted=0, block="general", hidden=0):
    """同步 vec_entries 中的一行（删除旧行再插入新行）。blob=None 表示删除。"""
    conn.execute("DELETE FROM vec_entries WHERE entry_id = ?", (entry_id,))
    if blob is not None:
        conn.execute(
            "INSERT INTO vec_entries(entry_id, vec, source, deleted, block, hidden) "
            "VALUES (?,?,?,?,?,?)",
            (entry_id, blob, source, deleted, block, hidden),
        )


def _vec_sync_hidden(conn, entry_id, hidden):
    """只更新 vec_entries 行的 hidden 标记。"""
    r = conn.execute(
        "SELECT vec, source, deleted, block FROM vec_entries WHERE entry_id=?", (entry_id,)).fetchone()
    if r:
        _vec_sync(conn, entry_id, r[0], r[1], r[2], r[3], hidden)


def _rebuild_vec_index(conn):
    """重建 vec_entries（迁移/异常时调用）。"""
    conn.execute("DROP TABLE IF EXISTS vec_entries")
    conn.execute(VEC_SCHEMA)
    rows = conn.execute(
        "SELECT id, vec, source, deleted, block, superseded_by, consolidated_into FROM entries"
    ).fetchall()
    for r in rows:
        hidden = 1 if (r[5] or r[6] or r[3]) else 0
        _vec_sync(conn, r[0], r[1], r[2], r[3], r[4], hidden)
    conn.commit()


def _migrate(conn):
    """自动迁移：补齐列、建 vec 索引、记录版本。幂等且对运行中进程安全。"""
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA busy_timeout=30000")
    conn.executescript(SCHEMA)   # 先建表（新库），再补列（旧库）
    _ensure_columns(conn)
    if _vec_enable(conn):
        ver = conn.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()
        if not ver or ver[0] != SCHEMA_VERSION:
            _rebuild_vec_index(conn)
            conn.execute(
                "INSERT INTO meta(key,value) VALUES('schema_version',?) "
                "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
                (SCHEMA_VERSION,),
            )
            conn.commit()
            log("vec index (re)built, schema_version=", SCHEMA_VERSION)


def connect():
    os.makedirs(os.path.dirname(DB), exist_ok=True)
    conn = sqlite3.connect(DB, timeout=30)
    _migrate(conn)
    return conn


# ---------------- 基础查询 ----------------

def _entry_from_row(row):
    return {
        "id": row[0],
        "text": row[1],
        "vec": row[2],
        "source": row[3],
        "ts": row[4],
    }


ACTIVE_WHERE = "deleted=0 AND superseded_by=0 AND consolidated_into=0"


def count():
    conn = connect()
    try:
        return conn.execute("SELECT COUNT(*) FROM entries WHERE %s" % ACTIVE_WHERE).fetchone()[0]
    finally:
        conn.close()


def _count(conn):
    return conn.execute("SELECT COUNT(*) FROM entries WHERE %s" % ACTIVE_WHERE).fetchone()[0]


def list_texts(source, limit=None):
    """返回某来源的全部（活跃）记忆文本（按写入顺序）。供守护进程反思/提炼用。"""
    conn = connect()
    try:
        if limit:
            return [r[0] for r in conn.execute(
                "SELECT text FROM entries WHERE source=? AND %s ORDER BY id LIMIT ?" % ACTIVE_WHERE,
                (source, limit)).fetchall()]
        return [r[0] for r in conn.execute(
            "SELECT text FROM entries WHERE source=? AND %s ORDER BY id" % ACTIVE_WHERE,
            (source,)).fetchall()]
    finally:
        conn.close()


def _fetch_all(conn, scope=None, block=None):
    """暴力检索路径用：拉取全部活跃条目（含新列）。"""
    sql = ("SELECT id,text,vec,source,ts,created_ms,deleted,block,importance,kind,origin,"
           "superseded_by,consolidated_into FROM entries WHERE %s" % ACTIVE_WHERE)
    params = []
    if scope:
        sql += " AND source=?"
        params.append(scope)
    if block:
        sql += " AND block=?"
        params.append(block)
    sql += " ORDER BY id"
    return conn.execute(sql, params).fetchall()


def get_entry(eid):
    conn = connect()
    try:
        return conn.execute(
            "SELECT id,text,vec,source,ts,created_ms,deleted,block,importance,kind,origin,"
            "superseded_by,consolidated_into FROM entries WHERE id=?", (eid,)).fetchone()
    finally:
        conn.close()


def list_entries(limit=20, offset=0, scope=None, block=None, keyword=None):
    """list_memories 工具用。返回活跃条目列表（id 倒序）。"""
    conn = connect()
    try:
        sql = ("SELECT id,text,source,ts,block,kind,importance FROM entries "
               "WHERE %s" % ACTIVE_WHERE)
        params = []
        if scope:
            sql += " AND source=?"
            params.append(scope)
        if block:
            sql += " AND block=?"
            params.append(block)
        if keyword:
            sql += " AND text LIKE ?"
            params.append("%" + keyword + "%")
        sql += " ORDER BY id DESC LIMIT ? OFFSET ?"
        params += [int(limit), int(offset)]
        rows = conn.execute(sql, params).fetchall()
        out = []
        for r in rows:
            out.append({
                "id": r[0], "text": r[1], "source": r[2], "ts": r[3],
                "block": r[4], "kind": r[5], "importance": r[6],
            })
        return out
    finally:
        conn.close()


def list_blocks():
    conn = connect()
    try:
        return conn.execute(
            "SELECT block, COUNT(*) FROM entries WHERE %s GROUP BY block ORDER BY 2 DESC"
            % ACTIVE_WHERE).fetchall()
    finally:
        conn.close()


# ---------------- 历史留痕 ----------------

def _history(conn, entry_id, action, old_text=None, new_text=None, source=None):
    conn.execute(
        "INSERT INTO entry_history(entry_id,ts,action,old_text,new_text,source) VALUES(?,?,?,?,?,?)",
        (entry_id, time.strftime("%Y-%m-%d %H:%M:%S"), action, old_text, new_text, source),
    )


# ---------------- 冲突处理（Mem0 式 + supersede） ----------------

def _resolve_conflict(new_text, candidates, timeout=180):
    """调本地 qwen3-14b 判断新记忆如何处理。失败返回 {'action':'new'}。"""
    cand_lines = "\n".join(f"[{i+1}] {c}" for i, c in enumerate(candidates))
    system = (
        '你是记忆库维护器。写入一条新记忆时发现它与库中已有记忆高度相似，'
        '请判断如何处理。只输出 JSON，不要任何其他文字。\n'
        '可选动作：\n'
        '- {"action":"new"}：新记忆是不同的事实，应新增\n'
        '- {"action":"update","id":N,"text":"..."}：新记忆更准确/更新，覆盖第 N 条\n'
        '- {"action":"merge","id":N,"text":"..."}：两者互补，合并成一条写入第 N 条\n'
        '- {"action":"skip","id":N}：新记忆与第 N 条重复/已被涵盖，不写入\n'
        '- {"action":"supersede","id":N}：新记忆与第 N 条矛盾且新记忆更准确，'
        '新增新记忆并把第 N 条标记为过时\n'
    )
    user = f"新记忆：{new_text}\n已有记忆：\n{cand_lines}"
    try:
        content = _chat_local(
            [{"role": "system", "content": system},
             {"role": "user", "content": user}],
            timeout=timeout)
        d = json.loads(content)
        if d.get("action") in ("new", "update", "merge", "skip", "supersede"):
            return d
    except Exception as e:
        log("conflict resolve failed:", e)
    return {"action": "new"}


# ---------------- 写入 ----------------

def add_entry(text, source, vec, conflict=False, timeout=180, block="general",
              importance=0.5, kind="semantic", origin="", extract_facts=False):
    """写一条记忆。返回 {"action": added|updated|merged|skipped|superseded, "id", "total", ...}。
    conflict=False 为快速路径：完全去重 + 0.90 相似去重（守护进程/归档用）。
    conflict=True 对齐 Mem0：相似召回 + LLM 决策 new/update/merge/skip/supersede。
    v2 修复：update/merge 覆盖文本时同步重算向量（旧版 bug：向量与文本失配）。
    """
    text = (text or "").strip()
    if not text:
        return {"action": "skipped", "reason": "empty"}
    blob = _vec_to_blob(vec)
    conn = connect()
    try:
        # 完全去重（活跃条目）
        row = conn.execute(
            "SELECT id FROM entries WHERE text=? AND %s" % ACTIVE_WHERE, (text,)).fetchone()
        if row:
            return {"action": "skipped", "id": row[0], "total": _count(conn), "reason": "exact_dup"}

        # 相似召回
        if _has_vec(conn):
            cand_rows = _ann_candidates(conn, blob, k=40)
        else:
            rows = _fetch_all(conn)
            scores = _cosine_batch(blob, [r[2] for r in rows]) if rows else []
            cand_rows = sorted(zip(scores, rows), key=lambda x: x[0], reverse=True)[:40]
        scored = [(s, r) for s, r in cand_rows]
        # >=0.90 视为确定重复，直接跳过
        if scored and scored[0][0] >= DUP_THRESHOLD:
            return {"action": "skipped", "id": scored[0][1][0], "total": _count(conn),
                    "reason": "sim_dup_%.2f" % scored[0][0]}
        # Mem0 式冲突决策（慢路径）
        if conflict:
            cands = [r for s, r in scored[:3] if s >= CONFLICT_THRESHOLD]
            if cands:
                decision = _resolve_conflict(text, [r[1] for r in cands], timeout=timeout)
                act = decision.get("action")
                cidx = decision.get("id")
                real_id = cands[cidx - 1][0] if (
                    isinstance(cidx, int) and 1 <= cidx <= len(cands)) else None
                if act == "update" and real_id is not None:
                    new_text = (decision.get("text") or text).strip()
                    old = conn.execute("SELECT text FROM entries WHERE id=?", (real_id,)).fetchone()
                    new_blob = _reembed_or_fallback(new_text, blob)
                    conn.execute("UPDATE entries SET text=?, vec=?, ts=? WHERE id=?",
                                 (new_text, new_blob, time.strftime("%Y-%m-%d %H:%M:%S"), real_id))
                    meta = conn.execute("SELECT source, block FROM entries WHERE id=?",
                                        (real_id,)).fetchone()
                    _vec_sync(conn, real_id, new_blob, meta[0], 0, meta[1], 0)
                    _history(conn, real_id, "update", old[0] if old else None, new_text, source)
                    conn.commit()
                    return {"action": "updated", "id": real_id, "total": _count(conn), "text": new_text}
                if act == "merge" and real_id is not None:
                    new_text = (decision.get("text") or text).strip()
                    old = conn.execute("SELECT text FROM entries WHERE id=?", (real_id,)).fetchone()
                    new_blob = _reembed_or_fallback(new_text, blob)
                    conn.execute("UPDATE entries SET text=?, vec=?, ts=? WHERE id=?",
                                 (new_text, new_blob, time.strftime("%Y-%m-%d %H:%M:%S"), real_id))
                    meta = conn.execute("SELECT source, block FROM entries WHERE id=?",
                                        (real_id,)).fetchone()
                    _vec_sync(conn, real_id, new_blob, meta[0], 0, meta[1], 0)
                    _history(conn, real_id, "merge", old[0] if old else None, new_text, source)
                    conn.commit()
                    return {"action": "merged", "id": real_id, "total": _count(conn), "text": new_text}
                if act == "supersede" and real_id is not None:
                    # 新记忆更准确：插入新条目，旧条目标记过时（Graphiti 式事实失效）
                    cur = conn.execute(
                        "INSERT INTO entries(text,vec,source,ts,created_ms,deleted,block,"
                        "importance,kind,origin,superseded_by,consolidated_into) "
                        "VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
                        (text, blob, source, time.strftime("%Y-%m-%d %H:%M:%S"),
                         int(time.time() * 1000), 0, block, float(importance), kind, origin, 0, 0))
                    new_id = cur.lastrowid
                    conn.execute(
                        "UPDATE entries SET superseded_by=?, ts=? WHERE id=?",
                        (new_id, time.strftime("%Y-%m-%d %H:%M:%S"), real_id))
                    old = conn.execute("SELECT text FROM entries WHERE id=?", (real_id,)).fetchone()
                    _history(conn, real_id, "superseded", old[0] if old else None, text, source)
                    _vec_sync(conn, new_id, blob, source, 0, block, 0)
                    _vec_sync_hidden(conn, real_id, 1)
                    conn.commit()
                    return {"action": "superseded", "id": new_id, "superseded_old": real_id,
                            "total": _count(conn)}
                if act == "skip" and real_id is not None:
                    return {"action": "skipped", "id": real_id, "total": _count(conn),
                            "reason": "conflict_skip"}
                # 其余（含 new / 解析失败）落回追加
        cur = conn.execute(
            "INSERT INTO entries(text,vec,source,ts,created_ms,deleted,block,"
            "importance,kind,origin,superseded_by,consolidated_into) "
            "VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
            (text, blob, source, time.strftime("%Y-%m-%d %H:%M:%S"),
             int(time.time() * 1000), 0, block, float(importance), kind, origin, 0, 0))
        new_id = cur.lastrowid
        _vec_sync(conn, new_id, blob, source, 0, block, 0)
        conn.commit()
        result = {"action": "added", "id": new_id, "total": _count(conn)}
        if extract_facts:
            try:
                _extract_facts_entry(conn, new_id, text)
            except Exception as e:
                log("facts extraction failed (non-blocking):", e)
        return result
    finally:
        conn.close()


def _reembed_or_fallback(new_text, fallback_blob):
    """重算新文本向量；Ollama 不可用时回退旧向量（宁可向量稍旧也不写失败）。"""
    try:
        return _vec_to_blob(_embed_local(new_text))
    except Exception as e:
        log("re-embed failed, fallback to old vec:", e)
        return fallback_blob


def update_entry(eid, new_text, source_hint=None):
    """update_memory 工具用：按 id 覆盖文本并重嵌向量，留历史。"""
    new_text = (new_text or "").strip()
    if not new_text:
        return {"action": "error", "reason": "empty text"}
    conn = connect()
    try:
        old = conn.execute("SELECT text FROM entries WHERE id=?", (eid,)).fetchone()
        if not old:
            return {"action": "error", "reason": "not_found"}
        new_blob = _reembed_or_fallback(new_text, None)
        if new_blob is None:
            return {"action": "error", "reason": "embed_failed"}
        r = conn.execute("SELECT source, block FROM entries WHERE id=?", (eid,)).fetchone()
        conn.execute("UPDATE entries SET text=?, vec=?, ts=? WHERE id=?",
                     (new_text, new_blob, time.strftime("%Y-%m-%d %H:%M:%S"), eid))
        _vec_sync(conn, eid, new_blob, r[0], 0, r[1], 0)
        _history(conn, eid, "update", old[0], new_text, source_hint)
        conn.commit()
        return {"action": "updated", "id": eid, "text": new_text}
    finally:
        conn.close()


def soft_delete(eid, source_hint=None):
    """forget 工具用：软删除（可恢复），留历史。"""
    conn = connect()
    try:
        old = conn.execute("SELECT text FROM entries WHERE id=? AND %s" % ACTIVE_WHERE,
                           (eid,)).fetchone()
        if not old:
            return {"action": "error", "reason": "not_found_or_inactive"}
        conn.execute("UPDATE entries SET deleted=1, ts=? WHERE id=?",
                     (time.strftime("%Y-%m-%d %H:%M:%S"), eid))
        _history(conn, eid, "delete", old[0], None, source_hint)
        # vec_entries: 标记 deleted（KNN 过滤）
        r = conn.execute("SELECT vec, source, block FROM vec_entries WHERE entry_id=?",
                         (eid,)).fetchone()
        if r:
            _vec_sync(conn, eid, r[0], r[1], 1, r[2], 0)
        # 清理关联 facts
        conn.execute("DELETE FROM facts WHERE entry_id=?", (eid,))
        conn.commit()
        return {"action": "deleted", "id": eid, "text": old[0]}
    finally:
        conn.close()


def find_best_match(query_vec, query_text, scope=None, block=None, min_score=0.35):
    """按查询找最匹配的一条活跃记忆（update_memory/forget 模糊模式用）。"""
    hits = search(query_vec, query_text, top_k=1, scope=scope, block=block,
                  min_score=min_score)
    return hits[0] if hits else None


# ---------------- ANN 候选 ----------------

def _ann_candidates(conn, qblob, k=40, scope=None, block=None):
    """sqlite-vec KNN 召回，返回 [(cos, row), ...]，row 为 _fetch_all 同构元组。"""
    conds = ["deleted = 0", "hidden = 0"]
    params = []
    if scope:
        conds.append("source = ?")
        params.append(scope)
    if block:
        conds.append("block = ?")
        params.append(block)
    sql = ("SELECT entry_id, distance FROM vec_entries WHERE %s AND vec MATCH ? AND k=%d"
           % (" AND ".join(conds), int(k)))
    params.append(qblob)
    result = conn.execute(sql, params).fetchall()
    if not result:
        return []
    dists = {r[0]: r[1] for r in result}
    ids = list(dists.keys())
    qs = ",".join("?" * len(ids))
    rows = conn.execute(
        "SELECT id,text,vec,source,ts,created_ms,deleted,block,importance,kind,origin,"
        "superseded_by,consolidated_into FROM entries WHERE id IN (%s)" % qs, ids).fetchall()
    by_id = {r[0]: r for r in rows}
    # distance 为余弦距离 (1-cos)
    out = []
    for eid in ids:
        r = by_id.get(eid)
        if r is None:
            continue
        cos = 1.0 - dists.get(eid, 1.0)
        out.append((cos, r))
    return out


# ---------------- rerank（可插拔：Ollama → 本地 fastembed 服务 → 降级） ----------------

_RERANK_STATE = {"ollama": ("unknown", 0.0), "local": ("unknown", 0.0), "last_spawn": 0.0}


def _rerank_ollama(query, docs):
    """探测并调用 Ollama /api/rerank。结果缓存状态，不可用快速返回 None。"""
    st = _RERANK_STATE["ollama"]
    now = time.time()
    if st[0] == "down" and now - st[1] < 600:
        return None
    try:
        payload = {"model": RERANK_MODEL, "query": query, "documents": docs}
        req = urllib.request.Request(
            OLLAMA + "/api/rerank",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        scores = {d.get("index"): d.get("relevance_score", 0.0)
                  for d in data.get("results", [])}
        _RERANK_STATE["ollama"] = ("ok", now)
        return scores
    except Exception:
        _RERANK_STATE["ollama"] = ("down", now)
        return None


def _local_rerank_probe(timeout=2.0):
    try:
        with urllib.request.urlopen(RERANK_LOCAL_URL + "/health", timeout=timeout) as resp:
            return resp.status == 200
    except Exception:
        return False


def _local_rerank_spawn():
    """懒启动本地 rerank 服务（首次模型加载约 10~40s）。"""
    now = time.time()
    if now - _RERANK_STATE["last_spawn"] < 300:
        return False
    _RERANK_STATE["last_spawn"] = now
    if not os.path.exists(RERANK_VENV_PY) or not os.path.exists(RERANK_SERVICE_PY):
        log("rerank service files missing, skip spawn")
        return False
    try:
        if os.name == "nt":
            subprocess.Popen(
                [RERANK_VENV_PY, RERANK_SERVICE_PY],
                creationflags=subprocess.CREATE_NO_WINDOW | subprocess.DETACHED_PROCESS,
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL, close_fds=True)
        else:
            subprocess.Popen(
                [RERANK_VENV_PY, RERANK_SERVICE_PY],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL, close_fds=True)
        log("rerank service spawned (lazy)")
    except Exception as e:
        log("rerank spawn failed:", e)
        return False
    # 等待就绪（首次要下载/加载模型，最多等 60s）
    t0 = time.time()
    while time.time() - t0 < 60:
        if _local_rerank_probe(timeout=1.0):
            return True
        time.sleep(2)
    return False


def _rerank_local(query, docs):
    """调用本地 fastembed rerank 服务。不可用返回 None。"""
    st = _RERANK_STATE["local"]
    now = time.time()
    if st[0] == "down" and now - st[1] < 120:
        return None
    try:
        payload = {"query": query, "documents": docs}
        req = urllib.request.Request(
            RERANK_LOCAL_URL + "/rerank",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        scores = data.get("scores")
        if isinstance(scores, list) and len(scores) == len(docs):
            _RERANK_STATE["local"] = ("ok", now)
            return list(scores)
        raise ValueError("bad scores")
    except Exception:
        _RERANK_STATE["local"] = ("down", now)
        if _local_rerank_spawn():
            # 服务刚拉起，重试一次
            try:
                payload = {"query": query, "documents": docs}
                req = urllib.request.Request(
                    RERANK_LOCAL_URL + "/rerank",
                    data=json.dumps(payload).encode("utf-8"),
                    headers={"Content-Type": "application/json"},
                )
                with urllib.request.urlopen(req, timeout=30) as resp:
                    data = json.loads(resp.read().decode("utf-8"))
                scores = data.get("scores")
                if isinstance(scores, list) and len(scores) == len(docs):
                    _RERANK_STATE["local"] = ("ok", time.time())
                    return list(scores)
            except Exception:
                pass
        return None


# ---------------- 检索 ----------------

def _bm25_ids(conn, query_text, limit=15):
    """FTS5 trigram BM25 召回。中文/英文短词（>=3 字符）均支持。
    短于 3 字符的查询词走 LIKE 回退（trigram 对 2 字词无效）。"""
    tokens = re.findall(r"[\u4e00-\u9fff]{3,}|[A-Za-z0-9]{3,}", query_text or "")
    if not tokens:
        # 短词 LIKE 回退（如"海报"/"咖啡"这类双字词）
        try:
            like = "%" + (query_text or "").strip() + "%"
            rows = conn.execute(
                "SELECT id FROM entries WHERE text LIKE ? AND %s LIMIT ?" % ACTIVE_WHERE,
                (like, limit)).fetchall()
            return [r[0] for r in rows]
        except Exception as e:
            log("bm25 like fallback failed:", e)
            return []
    expr = " OR ".join('"%s"' % t for t in tokens[:8])
    try:
        rows = conn.execute(
            "SELECT rowid FROM entries_fts WHERE entries_fts MATCH ? "
            "ORDER BY bm25(entries_fts) LIMIT ?", (expr, limit)
        ).fetchall()
        return [r[0] for r in rows]
    except Exception as e:
        log("bm25 failed:", e)
        return []


def _decay_weight(created_ms, importance):
    """近因衰减 + 重要性：180 天权重减半，重要性 0.5 居中（0.5+imp 范围 0.5~1.5）。"""
    age_days = max(0.0, (time.time() - (created_ms or 0) / 1000.0) / 86400.0)
    recency = 0.5 ** (age_days / RECENCY_HALFLIFE_DAYS)
    return recency * (0.5 + float(importance or 0.5))


def search(query_vec, query_text, top_k=5, scope=None, min_score=VEC_MIN_SCORE,
           use_rerank=True, block=None):
    """多路召回 + RRF 融合 +（可选精排）+ 时间衰减/重要性排序。
    返回 [{"id","text","source","ts","score","block","kind","importance"}]，
    score 为余弦相似度（显示用），排序用融合+衰减+重要性分数。"""
    qblob = _vec_to_blob(query_vec)
    conn = connect()
    try:
        # 向量召回（ANN 优先，暴力回退）
        if _has_vec(conn):
            cands = _ann_candidates(conn, qblob, k=60, scope=scope, block=block)
            vec_cands = [(r, s) for s, r in cands[:40]]
        else:
            rows = _fetch_all(conn, scope=scope, block=block)
            if not rows:
                return []
            scores = _cosine_batch(qblob, [r[2] for r in rows])
            order = sorted(range(len(rows)), key=lambda i: scores[i], reverse=True)
            vec_cands = [(rows[i], scores[i]) for i in order[:40]]
        # BM25 召回（同样应用 scope/block 过滤）
        bm25_ids = _bm25_ids(conn, query_text, limit=15)
        active_ids = set()
        if bm25_ids:
            qs = ",".join("?" * len(bm25_ids))
            sql2 = "SELECT id FROM entries WHERE id IN (%s) AND %s" % (qs, ACTIVE_WHERE)
            params2 = list(bm25_ids)
            if scope:
                sql2 += " AND source=?"
                params2.append(scope)
            if block:
                sql2 += " AND block=?"
                params2.append(block)
            active_ids = {r[0] for r in conn.execute(sql2, params2).fetchall()}
        # RRF 融合
        k = RRF_K
        rrf = {}
        for rank, (row, _s) in enumerate(vec_cands):
            rrf[row[0]] = rrf.get(row[0], 0.0) + 1.0 / (k + rank + 1)
        for rank, eid in enumerate(bm25_ids):
            if eid in active_ids:
                rrf[eid] = rrf.get(eid, 0.0) + 1.0 / (k + rank + 1)
        by_id = {r[0]: (r, s) for r, s in vec_cands}
        for eid in bm25_ids:
            if eid not in by_id and eid in active_ids:
                m = conn.execute(
                    "SELECT id,text,vec,source,ts,created_ms,deleted,block,importance,kind,"
                    "origin,superseded_by,consolidated_into FROM entries WHERE id=?",
                    (eid,)).fetchone()
                if m:
                    cos = _cosine_pair(qblob, m[2])
                    by_id[eid] = (m, cos)
        fused = sorted(rrf.keys(), key=lambda eid: rrf[eid], reverse=True)
        if not fused:
            return []
        # 可选精排（先 Ollama，再本地服务）
        base = None  # base[eid] = 精排分；None 表示未精排
        pool = fused[: max(top_k * 3, 15)]
        pool = [eid for eid in pool if eid in by_id]
        if use_rerank and len(pool) >= 2:
            pool_docs = [by_id[eid][0][1] for eid in pool]
            rs = _rerank_ollama(query_text, pool_docs)
            if rs is None:
                rs = _rerank_local(query_text, pool_docs)
            if rs is not None:
                base = {}
                for i, eid in enumerate(pool):
                    base[eid] = rs[i]
                keep = {eid for i, eid in enumerate(pool) if rs[i] >= 0.1}
                fused = [eid for eid in fused if eid in keep] or fused
        # 排序：精排分（无则归一化 RRF 分） × 近因衰减 × 重要性
        if base is not None:
            def rank_key(eid):
                return base.get(eid, 0.0) * _decay_weight(
                    by_id[eid][0][5], by_id[eid][0][8])
        else:
            max_rrf = max(rrf.values()) if rrf else 1.0
            def rank_key(eid):
                return (rrf.get(eid, 0.0) / max_rrf) * _decay_weight(
                    by_id[eid][0][5], by_id[eid][0][8])
        fused.sort(key=rank_key, reverse=True)
        # 组装结果
        out = []
        for eid in fused:
            row, cos = by_id[eid]
            if cos < min_score:
                continue
            out.append({"id": row[0], "text": row[1], "source": row[3],
                        "ts": row[4], "score": round(cos, 4),
                        "block": row[7], "kind": row[9], "importance": row[8]})
            if len(out) >= top_k:
                break
        return out
    finally:
        conn.close()


# ---------------- 知识图谱（轻量 facts 三元组） ----------------

FACTS_SYSTEM = (
    '你是知识抽取器。从给定记忆文本中抽取结构化事实三元组，只输出 JSON 数组，不要任何其他文字。\n'
    '格式: [{"entity":"主体","attribute":"属性","value":"值"}]\n'
    '规则: 主体/属性/值都用简短中文；一条记忆最多抽取 3 条；没有可抽取的事实就输出 []；'
    '只抽取文本中明确出现的信息，禁止推测。'
)


def _extract_facts_entry(conn, entry_id, text):
    """对单条记忆抽取事实三元组并写入 facts 表。"""
    content = _chat_local(
        [{"role": "system", "content": FACTS_SYSTEM},
         {"role": "user", "content": text}], timeout=180)
    try:
        arr = json.loads(content)
    except Exception:
        # 容错：截取 [ ... ] 部分再解析
        m = re.search(r"\[.*\]", content, re.S)
        if not m:
            return 0
        try:
            arr = json.loads(m.group(0))
        except Exception:
            return 0
    n = 0
    for item in arr[:3]:
        if not isinstance(item, dict):
            continue
        ent = (item.get("entity") or "").strip()
        attr = (item.get("attribute") or "").strip()
        val = (item.get("value") or "").strip()
        if not ent or not attr or not val:
            continue
        conn.execute(
            "INSERT INTO facts(entry_id,entity,attribute,value,ts) VALUES(?,?,?,?,?)",
            (entry_id, ent, attr, val, time.strftime("%Y-%m-%d %H:%M:%S")))
        n += 1
    conn.commit()
    return n


def refresh_facts(source=None, limit=50, dry_run=False):
    """为还没有事实的活跃条目补抽事实（后台维护用）。返回处理的条目数。"""
    conn = connect()
    try:
        sql = ("SELECT e.id, e.text FROM entries e "
               "WHERE %s AND e.id NOT IN (SELECT DISTINCT entry_id FROM facts)" % ACTIVE_WHERE)
        params = []
        if source:
            sql += " AND e.source=?"
            params.append(source)
        sql += " ORDER BY e.id LIMIT ?"
        params.append(int(limit))
        rows = conn.execute(sql, params).fetchall()
        if dry_run:
            return len(rows)
        done = 0
        for eid, text in rows:
            try:
                if _extract_facts_entry(conn, eid, text) > 0:
                    done += 1
            except Exception as e:
                log("refresh_facts entry %d failed: %s" % (eid, e))
        return done
    finally:
        conn.close()


def facts_search(query_text, top_k=8):
    """recall_facts 工具用：FTS 检索事实三元组，联表取活跃记忆文本。"""
    query_text = (query_text or "").strip()
    if not query_text:
        return []
    tokens = re.findall(r"[\u4e00-\u9fff]{3,}|[A-Za-z0-9]{3,}", query_text)
    conn = connect()
    try:
        rows = []
        if tokens:
            expr = " OR ".join('"%s"' % t for t in tokens[:8])
            try:
                rows = conn.execute(
                    "SELECT f.id, f.entity, f.attribute, f.value, f.entry_id "
                    "FROM facts_fts ff JOIN facts f ON f.id=ff.rowid "
                    "WHERE facts_fts MATCH ? ORDER BY bm25(facts_fts) LIMIT ?",
                    (expr, int(top_k) * 3)).fetchall()
            except Exception as e:
                log("facts fts failed:", e)
                rows = []
        if not rows:
            # 短词 LIKE 回退
            like = "%" + query_text + "%"
            rows = conn.execute(
                "SELECT f.id, f.entity, f.attribute, f.value, f.entry_id FROM facts f "
                "WHERE f.entity LIKE ? OR f.attribute LIKE ? OR f.value LIKE ? LIMIT ?",
                (like, like, like, int(top_k) * 3)).fetchall()
        out = []
        seen = set()
        for fid, ent, attr, val, eid in rows:
            er = conn.execute(
                "SELECT text, source FROM entries WHERE id=? AND %s" % ACTIVE_WHERE,
                (eid,)).fetchone()
            if not er:
                continue
            if fid in seen:
                continue
            seen.add(fid)
            out.append({"fact": "%s[%s]=%s" % (ent, attr, val),
                        "entry_id": eid, "text": er[0], "source": er[1]})
            if len(out) >= top_k:
                break
        return out
    finally:
        conn.close()


# ---------------- 维护：去重 / 固化 ----------------

def dedup(source, threshold=DUP_THRESHOLD):
    """对某来源活跃条目两两 >threshold 相似去重（软删除旧保留新）。返回移除数。"""
    conn = connect()
    try:
        rows = conn.execute(
            "SELECT id, vec, created_ms FROM entries WHERE source=? AND %s ORDER BY created_ms"
            % ACTIVE_WHERE, (source,)).fetchall()
        if len(rows) < 2:
            return 0
        blobs = [r[1] for r in rows]
        removed = set()
        if _np is not None and len(rows) <= 5000:
            dim = len(_np.frombuffer(blobs[0], dtype="<f4"))
            V = _np.frombuffer(b"".join(blobs), dtype="<f4").reshape(len(rows), dim)
            V = V / (_np.linalg.norm(V, axis=1, keepdims=True) + 1e-9)
            S = V @ V.T
            for i in range(len(rows)):
                if rows[i][0] in removed:
                    continue
                for j in range(i + 1, len(rows)):
                    if rows[j][0] in removed:
                        continue
                    if float(S[i, j]) >= threshold:
                        removed.add(rows[j][0])  # 删旧（created_ms 小者在前）
        else:
            for i in range(len(rows)):
                if rows[i][0] in removed:
                    continue
                for j in range(i + 1, len(rows)):
                    if rows[j][0] in removed:
                        continue
                    if _cosine_pair(blobs[i], blobs[j]) >= threshold:
                        removed.add(rows[j][0])
        if removed:
            for eid in removed:
                conn.execute("UPDATE entries SET deleted=1 WHERE id=?", (eid,))
                r = conn.execute("SELECT vec, source, block FROM vec_entries WHERE entry_id=?",
                                 (eid,)).fetchone()
                if r:
                    _vec_sync(conn, eid, r[0], r[1], 1, r[2], 0)
                _history(conn, eid, "dedup_delete", None, None, source)
            conn.commit()
        return len(removed)
    finally:
        conn.close()


CONSOLIDATE_SYSTEM = (
    "你是记忆库整理器。把多条相关的记忆合并成 1~5 条更高层级的记忆。\n"
    "要求：保留关键事实、用户偏好、决定与结论；删除重复内容；合并互补细节；"
    "不推测、不编造；每条一行，以 '- ' 开头，只输出条目本身，不要解释。"
)


def find_clusters(source=None, block=None, sim=0.55, min_cluster=3, limit=5):
    """贪心聚类：返回 [(代表向量 blob, [条目id,...]), ...]，按簇大小排序。"""
    conn = connect()
    try:
        sql = ("SELECT id, text, vec FROM entries WHERE %s" % ACTIVE_WHERE)
        params = []
        if source:
            sql += " AND source=?"
            params.append(source)
        if block:
            sql += " AND block=?"
            params.append(block)
        rows = conn.execute(sql, params).fetchall()
        if len(rows) < min_cluster:
            return []
        clusters = []
        used = set()
        for i, (eid, text, blob) in enumerate(rows):
            if eid in used:
                continue
            group = [eid]
            used.add(eid)
            for j in range(i + 1, len(rows)):
                eid2 = rows[j][0]
                if eid2 in used:
                    continue
                if _cosine_pair(blob, rows[j][2]) >= sim:
                    group.append(eid2)
                    used.add(eid2)
                    if len(group) >= 8:
                        break
            if len(group) >= min_cluster:
                clusters.append((blob, group))
        clusters.sort(key=lambda c: len(c[1]), reverse=True)
        return clusters[:limit]
    finally:
        conn.close()


def consolidate_cluster(eids, dry_run=False):
    """把一个簇固化为 1~3 条高层级记忆，原条目 consolidated_into 指向新条目。"""
    conn = connect()
    try:
        qs = ",".join("?" * len(eids))
        texts = [r[0] for r in conn.execute(
            "SELECT text FROM entries WHERE id IN (%s) AND %s ORDER BY id" % (qs, ACTIVE_WHERE),
            eids).fetchall()]
        if len(texts) < 2:
            return {"action": "skip", "reason": "too_few"}
        if dry_run:
            return {"action": "dry_run", "count": len(texts), "sample": texts[:3]}
        content = _chat_local(
            [{"role": "system", "content": CONSOLIDATE_SYSTEM},
             {"role": "user", "content": "\n".join(texts)}], timeout=300)
        items = [l.strip().lstrip("- ").strip() for l in content.splitlines() if l.strip()]
        items = [i for i in items if len(i) >= 4][:5]
        if not items:
            return {"action": "skip", "reason": "llm_empty"}
        new_ids = []
        src = conn.execute("SELECT source FROM entries WHERE id=?", (eids[0],)).fetchone()
        src = src[0] if src else "未知"
        blk = conn.execute("SELECT block FROM entries WHERE id=?", (eids[0],)).fetchone()
        blk = blk[0] if blk else "general"
        for item in items:
            try:
                vec = _embed_local(item)
            except Exception:
                continue
            r = add_entry(item, src, vec, conflict=False, block=blk,
                          importance=0.7, kind="semantic", origin="consolidate")
            if r.get("action") in ("added", "updated", "merged", "superseded"):
                new_ids.append(r.get("id"))
        if not new_ids:
            return {"action": "skip", "reason": "no_new_written"}
        main_id = new_ids[0]
        for eid in eids:
            conn.execute("UPDATE entries SET consolidated_into=? WHERE id=?", (main_id, eid))
            r = conn.execute("SELECT vec, source, block FROM vec_entries WHERE entry_id=?",
                             (eid,)).fetchone()
            if r:
                _vec_sync(conn, eid, r[0], r[1], 0, r[2], 1)
            _history(conn, eid, "consolidated", None, "→ #%d" % main_id, src)
        conn.commit()
        return {"action": "consolidated", "count": len(eids), "new_ids": new_ids,
                "texts": items}
    finally:
        conn.close()


def run_consolidation(source=None, block=None, sim=0.55, min_cluster=3,
                      max_clusters=5, dry_run=False):
    """反思固化入口：聚类 + 逐簇固化。返回汇总。"""
    clusters = find_clusters(source=source, block=block, sim=sim,
                             min_cluster=min_cluster, limit=max_clusters)
    results = []
    for blob, eids in clusters:
        try:
            r = consolidate_cluster(eids, dry_run=dry_run)
            r["cluster_size"] = len(eids)
            results.append(r)
        except Exception as e:
            results.append({"action": "error", "reason": str(e)[:120]})
    return {"clusters": len(clusters), "results": results}


# ---------------- 迁移 ----------------

def migrate_from_json(path=OLD_JSON, dry_run=False):
    """把旧 memory.json 导入 sqlite（完全去重 + 0.90 相似去重，保留 ts 新者）。
    返回 {"total", "imported", "skipped"}。"""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return {"total": 0, "imported": 0, "skipped": 0, "error": str(e)}
    entries = data.get("entries", [])
    entries.sort(key=lambda e: e.get("ts", ""))
    imported = skipped = 0
    for e in entries:
        text = (e.get("text") or "").strip()
        vec = e.get("vec")
        if not text or not vec:
            skipped += 1
            continue
        r = add_entry(text, e.get("source") or "未知", vec, conflict=False)
        if r["action"] == "added":
            imported += 1
        else:
            skipped += 1
    return {"total": len(entries), "imported": imported, "skipped": skipped}


def stats():
    """诊断统计。"""
    conn = connect()
    try:
        out = {"db": DB}
        out["entries_active"] = conn.execute(
            "SELECT COUNT(*) FROM entries WHERE %s" % ACTIVE_WHERE).fetchone()[0]
        out["entries_total"] = conn.execute("SELECT COUNT(*) FROM entries").fetchone()[0]
        out["vec_index_rows"] = conn.execute("SELECT COUNT(*) FROM vec_entries").fetchone()[0] if _has_vec(conn) else 0
        out["history_rows"] = conn.execute("SELECT COUNT(*) FROM entry_history").fetchone()[0]
        out["facts_rows"] = conn.execute("SELECT COUNT(*) FROM facts").fetchone()[0]
        out["by_source"] = conn.execute(
            "SELECT source, COUNT(*) FROM entries WHERE %s GROUP BY source ORDER BY 2 DESC"
            % ACTIVE_WHERE).fetchall()
        return out
    finally:
        conn.close()


if __name__ == "__main__":
    print("store_engine self-test")
    print("count:", count())
    import json as _json
    print("stats:", _json.dumps(stats(), ensure_ascii=False, default=str))
    if "--migrate" in sys.argv:
        print("migrate:", migrate_from_json())
