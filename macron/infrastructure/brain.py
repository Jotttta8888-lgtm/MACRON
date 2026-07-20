
import os
import json
import sqlite3
import hashlib
import logging
import numpy as np
from typing import List, Dict, Optional, Tuple, Any
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)

@dataclass
class MemoryEntry:
    id: str
    content: str
    source: str
    category: str
    timestamp: str
    embedding: Optional[List[float]] = None
    metadata: Dict = None
    importance: float = 1.0

class SecondBrain:
    def __init__(self, data_dir=None, model_name=None):
        self.data_dir = Path(data_dir or os.path.expanduser("~/Documents/MACRON/brain"))
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.db_path = self.data_dir / "memory.db"
        self.index_path = self.data_dir / "vectors.index"
        self._model_name = model_name or "all-MiniLM-L6-v2"
        self._model = None
        self._embedding_dim = 384
        self._index = None
        self._id_map = {}
        self._init_database()
        self._load_index()
        logger.info(f"SecondBrain iniciado: {self.db_path}, entradas: {self.count()}")
    def _init_database(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("CREATE TABLE IF NOT EXISTS memories (id TEXT PRIMARY KEY, content TEXT, source TEXT, category TEXT, timestamp TEXT, embedding BLOB, metadata TEXT, importance REAL DEFAULT 1.0)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_category ON memories(category)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_timestamp ON memories(timestamp)")
            conn.execute("CREATE TABLE IF NOT EXISTS associations (id INTEGER PRIMARY KEY, source_id TEXT, target_id TEXT, relation TEXT, strength REAL)")
    def _load_index(self):
        try:
            import faiss
            if self.index_path.exists():
                self._index = faiss.read_index(str(self.index_path))
            else:
                self._index = faiss.IndexFlatIP(self._embedding_dim)
        except ImportError:
            logger.warning("faiss no instalado. Usando fallback lineal.")
            self._index = None
    def _get_model(self):
        if self._model is None:
            from sentence_transformers import SentenceTransformer
            self._model = SentenceTransformer(self._model_name)
        return self._model
    def remember(self, content, source="system", category="observation", metadata=None, importance=1.0):
        memory_id = hashlib.sha256(f"{content}{datetime.now().isoformat()}".encode()).hexdigest()[:16]
        timestamp = datetime.now().isoformat()
        embedding = self._embed(content)
        embedding_bytes = np.array(embedding, dtype=np.float32).tobytes()
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("INSERT INTO memories VALUES (?,?,?,?,?,?,?,?)",
                        (memory_id, content, source, category, timestamp, embedding_bytes, json.dumps(metadata or {}), importance))
        if self._index is not None:
            vector = np.array([embedding], dtype=np.float32)
            faiss_id = self._index.ntotal
            self._index.add(vector)
            self._id_map[faiss_id] = memory_id
            self._save_index()
        else:
            self._id_map[len(self._id_map)] = memory_id
        return memory_id
    def recall(self, query, top_k=5, category=None, min_importance=0.0):
        if self.count() == 0:
            return []
        query_embedding = self._embed(query)
        query_vector = np.array([query_embedding], dtype=np.float32)
        if self._index is not None and self._index.ntotal > 0:
            scores, indices = self._index.search(query_vector, min(top_k * 2, self._index.ntotal))
            candidates = []
            for score, idx in zip(scores[0], indices[0]):
                if idx >= 0 and idx in self._id_map:
                    candidates.append((self._id_map[idx], float(score)))
        else:
            candidates = self._linear_search(query_embedding, top_k * 2)
        results = []
        for memory_id, score in candidates:
            memory = self._get_by_id(memory_id)
            if memory is None:
                continue
            if category and memory["category"] != category:
                continue
            if memory["importance"] < min_importance:
                continue
            memory["similarity"] = score
            results.append(memory)
        results.sort(key=lambda x: x["similarity"] * x["importance"], reverse=True)
        return results[:top_k]
    def connect(self, source_id, target_id, relation, strength=1.0):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("INSERT INTO associations VALUES (NULL,?,?,?,?)", (source_id, target_id, relation, strength))
    def related(self, memory_id, relation=None):
        with sqlite3.connect(self.db_path) as conn:
            if relation:
                rows = conn.execute("SELECT target_id, relation, strength FROM associations WHERE source_id=? AND relation=?", (memory_id, relation)).fetchall()
            else:
                rows = conn.execute("SELECT target_id, relation, strength FROM associations WHERE source_id=?", (memory_id,)).fetchall()
        results = []
        for target_id, rel, strength in rows:
            memory = self._get_by_id(target_id)
            if memory:
                memory["relation"] = rel
                memory["strength"] = strength
                results.append(memory)
        return results
    def consolidate(self, days=7):
        cutoff = datetime.now().timestamp() - (days * 86400)
        with sqlite3.connect(self.db_path) as conn:
            old = conn.execute("SELECT id, content, category FROM memories WHERE timestamp < ? AND category != 'archived'", (datetime.fromtimestamp(cutoff).isoformat(),)).fetchall()
        if not old:
            return {"consolidated": 0, "summary": None}
        by_category = {}
        for mid, content, cat in old:
            by_category.setdefault(cat, []).append(content)
        summaries = []
        for cat, contents in by_category.items():
            summary = f"[Resumen {cat}]: {len(contents)} eventos. " + "; ".join(contents[:3])
            summaries.append(summary)
        summary_text = "\n".join(summaries)
        summary_id = self.remember(summary_text, source="system", category="archived", importance=0.5)
        with sqlite3.connect(self.db_path) as conn:
            for mid, _, _ in old:
                conn.execute("UPDATE memories SET category='archived' WHERE id=?", (mid,))
        return {"consolidated": len(old), "summary_id": summary_id, "summary": summary_text}
    def forget(self, memory_id=None, category=None, older_than_days=None):
        deleted = 0
        with sqlite3.connect(self.db_path) as conn:
            if memory_id:
                conn.execute("DELETE FROM memories WHERE id=?", (memory_id,))
                deleted = conn.total_changes
            elif category:
                conn.execute("DELETE FROM memories WHERE category=?", (category,))
                deleted = conn.total_changes
            elif older_than_days:
                cutoff = datetime.now().timestamp() - (older_than_days * 86400)
                conn.execute("DELETE FROM memories WHERE timestamp < ?", (datetime.fromtimestamp(cutoff).isoformat(),))
                deleted = conn.total_changes
        if deleted > 0:
            self._rebuild_index()
        return deleted
    def _embed(self, text):
        model = self._get_model()
        embedding = model.encode(text, convert_to_numpy=True, normalize_embeddings=True)
        return embedding.tolist()
    def _get_by_id(self, memory_id):
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT id, content, source, category, timestamp, metadata, importance FROM memories WHERE id=?", (memory_id,)).fetchone()
        if row is None:
            return None
        return {"id": row[0], "content": row[1], "source": row[2], "category": row[3], "timestamp": row[4], "metadata": json.loads(row[5] or "{}"), "importance": row[6]}
    def _linear_search(self, query_embedding, top_k):
        query = np.array(query_embedding)
        results = []
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT id, embedding FROM memories WHERE embedding IS NOT NULL").fetchall()
        for memory_id, emb_bytes in rows:
            emb = np.frombuffer(emb_bytes, dtype=np.float32)
            similarity = np.dot(query, emb) / (np.linalg.norm(query) * np.linalg.norm(emb))
            results.append((memory_id, float(similarity)))
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:top_k]
    def _save_index(self):
        if self._index is not None:
            import faiss
            faiss.write_index(self._index, str(self.index_path))
    def _rebuild_index(self):
        if self._index is None:
            return
        import faiss
        self._index = faiss.IndexFlatIP(self._embedding_dim)
        self._id_map = {}
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT id, embedding FROM memories WHERE category != 'archived'").fetchall()
        for i, (memory_id, emb_bytes) in enumerate(rows):
            emb = np.frombuffer(emb_bytes, dtype=np.float32)
            self._index.add(np.array([emb]))
            self._id_map[i] = memory_id
        self._save_index()
    def count(self):
        with sqlite3.connect(self.db_path) as conn:
            return conn.execute("SELECT COUNT(*) FROM memories").fetchone()[0]
    def stats(self):
        with sqlite3.connect(self.db_path) as conn:
            total = conn.execute("SELECT COUNT(*) FROM memories").fetchone()[0]
            by_cat = conn.execute("SELECT category, COUNT(*) FROM memories GROUP BY category").fetchall()
            avg_imp = conn.execute("SELECT AVG(importance) FROM memories").fetchone()[0]
        return {"total_memories": total, "by_category": {cat: count for cat, count in by_cat}, "average_importance": round(avg_imp or 0, 2), "index_type": "FAISS" if self._index else "linear", "model": self._model_name, "data_dir": str(self.data_dir)}
    def export(self, path):
        with sqlite3.connect(self.db_path) as conn:
            rows = conn.execute("SELECT * FROM memories").fetchall()
        memories = []
        for row in rows:
            memories.append({"id": row[0], "content": row[1], "source": row[2], "category": row[3], "timestamp": row[4], "metadata": json.loads(row[6] or "{}"), "importance": row[7]})
        with open(path, "w", encoding="utf-8") as f:
            json.dump(memories, f, indent=2, ensure_ascii=False)

_brain_instance = None
def get_brain(data_dir=None):
    global _brain_instance
    if _brain_instance is None:
        _brain_instance = SecondBrain(data_dir)
    return _brain_instance
