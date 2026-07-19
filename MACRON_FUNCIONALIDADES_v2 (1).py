#!/usr/bin/env python3
"""
MACRON - Agente IA Local para macOS
====================================
Version: 2.0 | Fecha: 2026-07-17
Hardware: MAC NEO (Apple Silicon ARM64)

20 funcionalidades avanzadas optimizadas para Apple Silicon.
"""

import os, sys, json, sqlite3, hashlib, subprocess, platform, shutil, re, time, threading, uuid, warnings
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any, Tuple, Union
from dataclasses import dataclass, field, asdict
from enum import Enum
from collections import deque
import tempfile

warnings.filterwarnings("ignore")

# ============================================================
# SECCION 0: CONFIGURACION GLOBAL
# ============================================================

class MacronConfig:
    BASE_DIR = Path.home() / ".macron"
    DATA_DIR = BASE_DIR / "data"
    MODELS_DIR = BASE_DIR / "models"
    LOGS_DIR = BASE_DIR / "logs"
    CACHE_DIR = BASE_DIR / "cache"

    IS_APPLE_SILICON = platform.machine() in ("arm64", "aarch64") and sys.platform == "darwin"
    IS_MACOS = sys.platform == "darwin"

    try:
        import psutil
        TOTAL_RAM_GB = psutil.virtual_memory().total / (1024**3)
    except ImportError:
        TOTAL_RAM_GB = 16

    HAS_MLX = False
    HAS_MPS = False

    if IS_APPLE_SILICON:
        try:
            import mlx, mlx.core as mx
            HAS_MLX = True
            print("[MACRON] MLX detectado - Neural Engine/GPU activo")
        except ImportError:
            pass
        try:
            import torch
            if torch.backends.mps.is_available():
                HAS_MPS = True
                print("[MACRON] MPS fallback disponible")
        except ImportError:
            pass

    @classmethod
    def get_model_size(cls) -> str:
        if cls.TOTAL_RAM_GB >= 32: return "30B"
        elif cls.TOTAL_RAM_GB >= 16: return "7B"
        else: return "1.5B"

    @classmethod
    def ensure_dirs(cls):
        for d in [cls.BASE_DIR, cls.DATA_DIR, cls.MODELS_DIR, cls.LOGS_DIR, cls.CACHE_DIR]:
            d.mkdir(parents=True, exist_ok=True)

    @classmethod
    def db_path(cls) -> Path:
        return cls.DATA_DIR / "macron.db"

    @classmethod
    def init_db(cls):
        cls.ensure_dirs()
        conn = sqlite3.connect(str(cls.db_path()))
        c = conn.cursor()

        tables = [
            ("memory", "id INTEGER PRIMARY KEY, key TEXT UNIQUE, value TEXT, category TEXT DEFAULT 'general', timestamp REAL, importance REAL DEFAULT 1.0"),
            ("logs", "id INTEGER PRIMARY KEY, level TEXT, message TEXT, module TEXT, timestamp REAL"),
            ("rutinas", "id INTEGER PRIMARY KEY, name TEXT UNIQUE, description TEXT, cron_expr TEXT, action_type TEXT, action_params TEXT, enabled INTEGER DEFAULT 1, last_run REAL, next_run REAL"),
            ("planes", "id INTEGER PRIMARY KEY, name TEXT, description TEXT, steps TEXT, status TEXT DEFAULT 'pending', created REAL, completed REAL"),
            ("vault", "id INTEGER PRIMARY KEY, key TEXT UNIQUE, encrypted_value TEXT, salt TEXT, created REAL"),
            ("rag_chunks", "id INTEGER PRIMARY KEY, file_path TEXT, chunk_hash TEXT UNIQUE, chunk_text TEXT, embedding BLOB, metadata TEXT, indexed_at REAL"),
            ("face_encodings", "id INTEGER PRIMARY KEY, name TEXT, encoding BLOB, image_path TEXT, created REAL"),
            ("intrusions", "id INTEGER PRIMARY KEY, timestamp REAL, image_path TEXT, confidence REAL, handled INTEGER DEFAULT 0"),
            ("transcriptions", "id INTEGER PRIMARY KEY, audio_path TEXT, text TEXT, language TEXT, duration REAL, created REAL"),
            ("cot_sessions", "id INTEGER PRIMARY KEY, session_id TEXT UNIQUE, title TEXT, steps TEXT, conclusion TEXT, created REAL, exported INTEGER DEFAULT 0"),
            ("devices", "id INTEGER PRIMARY KEY, device_id TEXT UNIQUE, device_name TEXT, device_type TEXT, last_sync REAL, sync_token TEXT"),
        ]

        for name, schema in tables:
            c.execute(f"CREATE TABLE IF NOT EXISTS {name} ({schema})")

        conn.commit()
        conn.close()
        print("[MACRON] Base de datos inicializada.")


# ============================================================
# SECCION 1: RAG ARCHIVOS (#1)
# ============================================================

class MacronRAG:
    SUPPORTED = {".pdf", ".docx", ".txt", ".md", ".csv", ".json", ".py", ".swift", ".html", ".js"}

    def __init__(self):
        MacronConfig.init_db()
        self.embedder = None
        self._init_embedder()

    def _init_embedder(self):
        try:
            from sentence_transformers import SentenceTransformer
            self.embedder = SentenceTransformer("all-MiniLM-L6-v2", device="cpu")
            print("[RAG] Embedder cargado")
        except ImportError:
            print("[RAG] Instala: pip install sentence-transformers")

    def _extract_text(self, path: str) -> str:
        p = Path(path)
        ext = p.suffix.lower()

        if ext == ".pdf":
            try:
                import PyPDF2
                text = ""
                with open(path, "rb") as f:
                    for page in PyPDF2.PdfReader(f).pages:
                        text += page.extract_text() or ""
                return text
            except ImportError:
                return "[PyPDF2 no instalado]"

        elif ext == ".docx":
            try:
                import docx
                return "\n".join([p.text for p in docx.Document(path).paragraphs])
            except ImportError:
                return "[python-docx no instalado]"

        elif ext in self.SUPPORTED:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                return f.read()
        return ""

    def _chunk(self, text: str, size: int = 512, overlap: int = 50) -> List[str]:
        words = text.split()
        chunks = []
        i = 0
        while i < len(words):
            chunks.append(" ".join(words[i:i+size]))
            i += size - overlap
        return chunks

    def _embed(self, text: str) -> Optional[bytes]:
        if self.embedder is None: return None
        import numpy as np
        return self.embedder.encode(text, convert_to_numpy=True).tobytes()

    def index_file(self, path: str) -> Dict:
        p = Path(path)
        if not p.exists(): return {"success": False, "error": "No encontrado"}
        if p.suffix.lower() not in self.SUPPORTED:
            return {"success": False, "error": f"Formato no soportado: {p.suffix}"}

        text = self._extract_text(path)
        if not text.strip(): return {"success": False, "error": "Sin texto extraible"}

        chunks = self._chunk(text)
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        indexed = 0

        for chunk in chunks:
            h = hashlib.sha256(chunk.encode()).hexdigest()
            emb = self._embed(chunk)
            try:
                c.execute("INSERT OR REPLACE INTO rag_chunks (file_path, chunk_hash, chunk_text, embedding, metadata, indexed_at) VALUES (?,?,?,?,?,?)",
                         (str(path), h, chunk, emb, json.dumps({"words": len(chunk.split())}), time.time()))
                indexed += 1
            except Exception as e:
                print(f"[RAG] Error: {e}")

        conn.commit(); conn.close()
        return {"success": True, "file": str(path), "chunks": indexed, "chars": len(text)}

    def search(self, query: str, top_k: int = 5) -> List[Dict]:
        if self.embedder is None: return [{"error": "Embedder no disponible"}]
        import numpy as np
        qemb = self.embedder.encode(query, convert_to_numpy=True)

        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT file_path, chunk_text, embedding FROM rag_chunks")
        rows = c.fetchall(); conn.close()

        results = []
        for fp, txt, emb_bytes in rows:
            if emb_bytes is None: continue
            cemb = np.frombuffer(emb_bytes, dtype=np.float32)
            sim = np.dot(qemb, cemb) / (np.linalg.norm(qemb) * np.linalg.norm(cemb))
            results.append({"file": fp, "text": txt[:300]+"..." if len(txt)>300 else txt, "sim": float(sim)})

        results.sort(key=lambda x: x["sim"], reverse=True)
        return results[:top_k]

    def list_indexed(self) -> List[str]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT DISTINCT file_path FROM rag_chunks")
        files = [r[0] for r in c.fetchall()]; conn.close()
        return files

    def delete_index(self, path: str) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("DELETE FROM rag_chunks WHERE file_path=?", (path,))
        conn.commit(); deleted = c.rowcount > 0; conn.close()
        return deleted


# ============================================================
# SECCION 2: PLANIFICACION VERIFICADA (#2)
# ============================================================

class MacronPlanning:
    def __init__(self):
        MacronConfig.init_db()

    def create(self, name: str, desc: str, steps: List[str]) -> Dict:
        sid = str(uuid.uuid4())[:8]
        steps_data = [{"id": i+1, "desc": s, "status": "pending", "verified": False, "notes": ""} for i, s in enumerate(steps)]

        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("INSERT INTO planes (name, description, steps, status, created) VALUES (?,?,?,?,?)",
                 (name, desc, json.dumps(steps_data), "pending", time.time()))
        dbid = c.lastrowid; conn.commit(); conn.close()
        return {"success": True, "plan_id": dbid, "name": name, "steps": len(steps)}

    def get(self, plan_id: int) -> Optional[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT * FROM planes WHERE id=?", (plan_id,))
        r = c.fetchone(); conn.close()
        if not r: return None
        return {"id": r[0], "name": r[1], "desc": r[2], "steps": json.loads(r[3]), "status": r[4], "created": r[5], "completed": r[6]}

    def list(self) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT id, name, description, status, created FROM planes ORDER BY created DESC")
        plans = [{"id": r[0], "name": r[1], "desc": r[2], "status": r[3], "created": datetime.fromtimestamp(r[4]).isoformat()} for r in c.fetchall()]
        conn.close(); return plans

    def update_step(self, plan_id: int, step_id: int, status: str, notes: str = "") -> bool:
        plan = self.get(plan_id)
        if not plan: return False
        steps = plan["steps"]
        for s in steps:
            if s["id"] == step_id:
                s["status"] = status; s["notes"] = notes
                if status == "completed": s["verified"] = True
                break
        all_done = all(s["status"] == "completed" for s in steps)
        new_status = "completed" if all_done else "in_progress"

        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("UPDATE planes SET steps=?, status=?, completed=? WHERE id=?",
                 (json.dumps(steps), new_status, time.time() if all_done else None, plan_id))
        conn.commit(); conn.close()
        return True

    def delete(self, plan_id: int) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("DELETE FROM planes WHERE id=?", (plan_id,))
        conn.commit(); deleted = c.rowcount > 0; conn.close()
        return deleted


# ============================================================
# SECCION 3: CHAIN-OF-THOUGHT (#4)
# ============================================================

class MacronCoT:
    def __init__(self):
        MacronConfig.init_db()

    def start(self, title: str = "CoT Session") -> str:
        sid = str(uuid.uuid4())
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("INSERT INTO cot_sessions (session_id, title, steps, created) VALUES (?,?,?,?)",
                 (sid, title, json.dumps([]), time.time()))
        conn.commit(); conn.close()
        return sid

    def add_step(self, sid: str, step_type: str, content: str, reasoning: str = "", confidence: float = 1.0) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT steps FROM cot_sessions WHERE session_id=?", (sid,))
        r = c.fetchone()
        if not r: conn.close(); return False
        steps = json.loads(r[0])
        steps.append({"id": len(steps)+1, "type": step_type, "content": content, "reasoning": reasoning, "confidence": confidence, "ts": time.time()})
        c.execute("UPDATE cot_sessions SET steps=? WHERE session_id=?", (json.dumps(steps), sid))
        conn.commit(); conn.close(); return True

    def get(self, sid: str) -> Optional[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT * FROM cot_sessions WHERE session_id=?", (sid,))
        r = c.fetchone(); conn.close()
        if not r: return None
        return {"id": r[0], "sid": r[1], "title": r[2], "steps": json.loads(r[3]), "conclusion": r[4], "created": r[5], "exported": bool(r[6])}

    def conclude(self, sid: str, conclusion: str) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("UPDATE cot_sessions SET conclusion=? WHERE session_id=?", (conclusion, sid))
        conn.commit(); conn.close(); return True

    def export_md(self, sid: str, out_path: Optional[str] = None) -> str:
        s = self.get(sid)
        if not s: return "# Error: Sesion no encontrada"
        md = f"# {s['title']}\n\n**ID:** `{sid}`\n**Creado:** {datetime.fromtimestamp(s['created']).isoformat()}\n\n## Pasos\n\n"
        for step in s["steps"]:
            md += f"### Paso {step['id']} - {step['type']}\n\n**Contenido:** {step['content']}\n\n"
            if step['reasoning']: md += f"**Razonamiento:** {step['reasoning']}\n\n"
            md += f"**Confianza:** {step['confidence']}\n\n---\n\n"
        if s["conclusion"]: md += f"## Conclusion\n\n{s['conclusion']}\n"
        if out_path:
            with open(out_path, "w") as f: f.write(md)
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("UPDATE cot_sessions SET exported=1 WHERE session_id=?", (sid,))
        conn.commit(); conn.close()
        return md

    def list_sessions(self) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT session_id, title, created, exported FROM cot_sessions ORDER BY created DESC")
        sessions = [{"sid": r[0], "title": r[1], "created": datetime.fromtimestamp(r[2]).isoformat(), "exported": bool(r[3])} for r in c.fetchall()]
        conn.close(); return sessions


# ============================================================
# SECCION 4: RUTINAS (#5)
# ============================================================

class MacronRutinas:
    def __init__(self):
        MacronConfig.init_db()
        self._running = False
        self._thread = None

    def _parse_cron(self, expr: str):
        parts = expr.split()
        if len(parts) != 5: raise ValueError("Formato: min hour day month dow")
        def matches(dt):
            for val, pat in [(dt.minute, parts[0]), (dt.hour, parts[1]), (dt.day, parts[2]), (dt.month, parts[3]), (dt.weekday(), parts[4])]:
                if pat == "*": continue
                if "/" in pat:
                    b, st = pat.split("/")
                    if b != "*" and val != int(b): return False
                    if val % int(st) != 0: return False
                elif "," in pat:
                    if val not in [int(x) for x in pat.split(",")]: return False
                elif "-" in pat:
                    a, z = map(int, pat.split("-"))
                    if not (a <= val <= z): return False
                elif val != int(pat): return False
            return True
        return matches

    def create(self, name: str, desc: str, cron: str, action_type: str, params: Dict) -> Dict:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        try:
            c.execute("INSERT INTO rutinas (name, description, cron_expr, action_type, action_params, next_run) VALUES (?,?,?,?,?,?)",
                     (name, desc, cron, action_type, json.dumps(params), time.time()))
            rid = c.lastrowid; conn.commit(); conn.close()
            return {"success": True, "id": rid, "name": name, "cron": cron}
        except sqlite3.IntegrityError:
            conn.close(); return {"success": False, "error": f"Rutina '{name}' ya existe"}

    def list(self) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT id, name, description, cron_expr, action_type, enabled, last_run FROM rutinas")
        ruts = [{"id": r[0], "name": r[1], "desc": r[2], "cron": r[3], "type": r[4], "enabled": bool(r[5]), "last_run": datetime.fromtimestamp(r[6]).isoformat() if r[6] else None} for r in c.fetchall()]
        conn.close(); return ruts

    def toggle(self, rid: int, enabled: bool) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("UPDATE rutinas SET enabled=? WHERE id=?", (1 if enabled else 0, rid))
        conn.commit(); ok = c.rowcount > 0; conn.close(); return ok

    def delete(self, rid: int) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("DELETE FROM rutinas WHERE id=?", (rid,))
        conn.commit(); ok = c.rowcount > 0; conn.close(); return ok

    def _exec(self, atype: str, params: Dict):
        if atype == "shell":
            subprocess.run(params.get("command", ""), shell=True, capture_output=True)
        elif atype == "python":
            exec(params.get("code", ""), {"__name__": "__main__"})
        elif atype == "notification":
            if MacronConfig.IS_MACOS:
                subprocess.run(["osascript", "-e", f'display notification "{params.get("message", "")}" with title "{params.get("title", "MACRON")}"'])
        elif atype == "open_app":
            if MacronConfig.IS_MACOS: subprocess.run(["open", "-a", params.get("app", "")])
        elif atype == "backup":
            src, dst = params.get("source", ""), params.get("destination", "")
            if os.path.exists(src): shutil.copytree(src, dst, dirs_exist_ok=True)

    def run_now(self, rid: int) -> Dict:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT action_type, action_params FROM rutinas WHERE id=?", (rid,))
        r = c.fetchone(); conn.close()
        if not r: return {"success": False, "error": "No encontrada"}
        try:
            self._exec(r[0], json.loads(r[1]))
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("UPDATE rutinas SET last_run=? WHERE id=?", (time.time(), rid))
            conn.commit(); conn.close()
            return {"success": True, "id": rid}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def start_scheduler(self):
        if self._running: return
        self._running = True
        def loop():
            while self._running:
                now = datetime.now()
                conn = sqlite3.connect(str(MacronConfig.db_path()))
                c = conn.cursor()
                c.execute("SELECT id, cron_expr, action_type, action_params FROM rutinas WHERE enabled=1")
                for row in c.fetchall():
                    try:
                        if self._parse_cron(row[1])(now):
                            self._exec(row[2], json.loads(row[3]))
                            c.execute("UPDATE rutinas SET last_run=? WHERE id=?", (time.time(), row[0]))
                    except Exception as e: print(f"[Scheduler] Error rutina {row[0]}: {e}")
                conn.commit(); conn.close(); time.sleep(60)
        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start(); print("[Rutinas] Scheduler activo.")

    def stop_scheduler(self):
        self._running = False
        if self._thread: self._thread.join(timeout=2)
        print("[Rutinas] Scheduler detenido.")


# ============================================================
# SECCION 5: RECONOCIMIENTO FACIAL (#9)
# ============================================================

class MacronFaceRec:
    def __init__(self):
        MacronConfig.init_db()
        self.detector = None; self.predictor = None; self.encoder = None
        self._init()

    def _init(self):
        try:
            import dlib
            self.detector = dlib.get_frontal_face_detector()
            mdir = MacronConfig.MODELS_DIR
            sp = mdir / "shape_predictor_68_face_landmarks.dat"
            fr = mdir / "dlib_face_recognition_resnet_model_v1.dat"
            if sp.exists() and fr.exists():
                self.predictor = dlib.shape_predictor(str(sp))
                self.encoder = dlib.face_recognition_model_v1(str(fr))
                print("[FaceRec] Modelos cargados")
            else:
                print(f"[FaceRec] Modelos faltantes en {mdir}")
        except ImportError:
            print("[FaceRec] Instala: brew install cmake && pip install dlib")

    def register(self, img_path: str, name: str) -> Dict:
        if self.encoder is None: return {"success": False, "error": "Modelos no cargados"}
        try:
            import cv2, dlib, numpy as np
            img = cv2.imread(img_path)
            if img is None: return {"success": False, "error": "Imagen no cargable"}
            rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            faces = self.detector(rgb)
            if len(faces) == 0: return {"success": False, "error": "Sin rostros"}
            if len(faces) > 1: return {"success": False, "error": f"{len(faces)} rostros detectados"}
            shape = self.predictor(rgb, faces[0])
            enc = np.array(self.encoder.compute_face_descriptor(rgb, shape))
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("INSERT INTO face_encodings (name, encoding, image_path, created) VALUES (?,?,?,?)",
                     (name, enc.tobytes(), img_path, time.time()))
            conn.commit(); conn.close()
            return {"success": True, "name": name}
        except Exception as e: return {"success": False, "error": str(e)}

    def recognize(self, img_path: str, tol: float = 0.6) -> Dict:
        if self.encoder is None: return {"success": False, "error": "Modelos no cargados"}
        try:
            import cv2, numpy as np
            img = cv2.imread(img_path)
            if img is None: return {"success": False, "error": "Imagen no cargable"}
            rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            faces = self.detector(rgb)
            if len(faces) == 0: return {"success": True, "faces": 0, "matches": []}

            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("SELECT name, encoding FROM face_encodings")
            known = [(r[0], np.frombuffer(r[1], dtype=np.float64)) for r in c.fetchall()]
            conn.close()

            matches = []
            for face in faces:
                shape = self.predictor(rgb, face)
                enc = np.array(self.encoder.compute_face_descriptor(rgb, shape))
                best, best_d = None, float("inf")
                for name, ke in known:
                    d = np.linalg.norm(enc - ke)
                    if d < best_d: best_d, best = d, name
                matches.append({"match": best if best_d < tol else "Desconocido", "conf": float(1-best_d), "dist": float(best_d)})
            return {"success": True, "faces": len(faces), "matches": matches}
        except Exception as e: return {"success": False, "error": str(e)}

    def list_registered(self) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT name, image_path, created FROM face_encodings")
        faces = [{"name": r[0], "img": r[1], "registered": datetime.fromtimestamp(r[2]).isoformat()} for r in c.fetchall()]
        conn.close(); return faces

    def delete(self, name: str) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("DELETE FROM face_encodings WHERE name=?", (name,))
        conn.commit(); ok = c.rowcount > 0; conn.close(); return ok


# ============================================================
# SECCION 6: NOTION (#12)
# ============================================================

class MacronNotion:
    BASE = "https://api.notion.com/v1"

    def __init__(self, token: Optional[str] = None):
        self.token = token or os.environ.get("NOTION_API_TOKEN")
        self.h = {"Authorization": f"Bearer {self.token}", "Content-Type": "application/json", "Notion-Version": "2022-06-28"} if self.token else {}

    def _req(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        if not self.token: return {"error": "Token no configurado"}
        try:
            import requests
            url = f"{self.BASE}{endpoint}"
            if method == "GET": r = requests.get(url, headers=self.h, timeout=10)
            elif method == "POST": r = requests.post(url, headers=self.h, json=data, timeout=10)
            elif method == "PATCH": r = requests.patch(url, headers=self.h, json=data, timeout=10)
            else: return {"error": f"Metodo {method} no soportado"}
            r.raise_for_status(); return r.json()
        except Exception as e: return {"error": str(e)}

    def list_dbs(self) -> List[Dict]:
        r = self._req("POST", "/search", {"filter": {"value":"database","property":"object"}})
        return r.get("results", [r]) if "error" not in r else [r]

    def query_db(self, db_id: str, filt: Optional[Dict] = None) -> List[Dict]:
        r = self._req("POST", f"/databases/{db_id}/query", {"filter": filt} if filt else {})
        return r.get("results", [r]) if "error" not in r else [r]

    def create_page(self, parent_id: str, title: str, content: str = "", props: Optional[Dict] = None) -> Dict:
        data = {"parent": {"database_id": parent_id} if props else {"page_id": parent_id},
                "properties": props or {"title": {"title": [{"text": {"content": title}}]}}}
        if content:
            data["children"] = [{"object": "block", "type": "paragraph", "paragraph": {"rich_text": [{"type": "text", "text": {"content": content}}]}}]
        return self._req("POST", "/pages", data)

    def update_page(self, page_id: str, props: Dict) -> Dict:
        return self._req("PATCH", f"/pages/{page_id}", {"properties": props})

    def sync_tasks(self, db_id: str) -> Dict:
        tasks = self.query_db(db_id)
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor(); synced = 0
        for t in tasks:
            if "error" in t: continue
            props = t.get("properties", {}); title = ""
            for k, v in props.items():
                if v.get("type") == "title":
                    title = "".join([x.get("text", {}).get("content", "") for x in v.get("title", [])])
                    break
            c.execute("INSERT OR REPLACE INTO memory (key, value, category, timestamp) VALUES (?,?,?,?)",
                     (f"notion_{t['id']}", json.dumps({"title": title, "id": t["id"], "url": t.get("url", "")}), "notion", time.time()))
            synced += 1
        conn.commit(); conn.close()
        return {"success": True, "synced": synced}


# ============================================================
# SECCION 7: MULTI-DISPOSITIVO (#14)
# ============================================================

class MacronMultiDevice:
    def __init__(self, name: Optional[str] = None):
        MacronConfig.init_db()
        self.device_id = self._get_id()
        self.device_name = name or platform.node()
        self.device_type = "mac" if sys.platform == "darwin" else "other"

    def _get_id(self) -> str:
        f = MacronConfig.BASE_DIR / ".device_id"
        if f.exists(): return f.read_text().strip()
        nid = str(uuid.uuid4()); f.write_text(nid); return nid

    def register(self) -> Dict:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("INSERT OR REPLACE INTO devices (device_id, device_name, device_type, last_sync, sync_token) VALUES (?,?,?,?,?)",
                 (self.device_id, self.device_name, self.device_type, time.time(), str(uuid.uuid4())))
        conn.commit(); conn.close()
        return {"success": True, "id": self.device_id, "name": self.device_name}

    def list_devices(self) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT device_id, device_name, device_type, last_sync FROM devices")
        devs = [{"id": r[0], "name": r[1], "type": r[2], "last_sync": datetime.fromtimestamp(r[3]).isoformat() if r[3] else None} for r in c.fetchall()]
        conn.close(); return devs

    def sync_memory(self) -> Dict:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT key, value, category, timestamp, importance FROM memory")
        mems = c.fetchall()
        c.execute("UPDATE devices SET last_sync=? WHERE device_id=?", (time.time(), self.device_id))
        conn.commit(); conn.close()
        data = {"from": self.device_id, "ts": time.time(), "memories": [{"key": r[0], "value": r[1], "cat": r[2], "ts": r[3], "imp": r[4]} for r in mems]}
        sf = MacronConfig.CACHE_DIR / f"sync_{self.device_id}_{int(time.time())}.json"
        with open(sf, "w") as f: json.dump(data, f, indent=2)
        return {"success": True, "entries": len(mems), "file": str(sf)}

    def import_sync(self, path: str) -> Dict:
        with open(path) as f: data = json.load(f)
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor(); imported = 0
        for m in data.get("memories", []):
            c.execute("INSERT OR REPLACE INTO memory (key, value, category, timestamp, importance) VALUES (?,?,?,?,?)",
                     (m["key"], m["value"], m["cat"], m["ts"], m.get("imp", 1.0)))
            imported += 1
        conn.commit(); conn.close()
        return {"success": True, "from": data.get("from"), "imported": imported}


# ============================================================
# SECCION 8: DETECCION DE INTRUSOS (#16)
# ============================================================

class MacronIntrusion:
    def __init__(self):
        MacronConfig.init_db()
        self.face = MacronFaceRec()
        self._monitoring = False; self._thread = None

    def capture(self, cam: int = 0) -> Optional[str]:
        try:
            import cv2
            cap = cv2.VideoCapture(cam)
            if not cap.isOpened(): return None
            ret, frame = cap.read(); cap.release()
            if not ret: return None
            p = MacronConfig.CACHE_DIR / f"cap_{int(time.time())}.jpg"
            cv2.imwrite(str(p), frame); return str(p)
        except ImportError:
            print("[Intrusos] Instala: pip install opencv-python"); return None

    def check(self, img_path: Optional[str] = None, cam: int = 0) -> Dict:
        if img_path is None:
            img_path = self.capture(cam)
            if img_path is None: return {"success": False, "error": "No se pudo capturar"}
        r = self.face.recognize(img_path, tol=0.5)
        if not r.get("success"): return r
        intruders = [m for m in r.get("matches", []) if m["match"] == "Desconocido"]
        if intruders:
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            for i in intruders:
                c.execute("INSERT INTO intrusions (timestamp, image_path, confidence, handled) VALUES (?,?,?,?)",
                         (time.time(), img_path, i["conf"], 0))
            conn.commit(); conn.close()
            if MacronConfig.IS_MACOS:
                subprocess.run(["osascript", "-e", 'display notification "Intruso detectado" with title "MACRON Alerta" sound name "Glass"'])
        return {"success": True, "intruders": len(intruders), "matches": intruders, "img": img_path}

    def start_monitor(self, interval: int = 5, cam: int = 0):
        if self._monitoring: return
        self._monitoring = True
        def loop():
            while self._monitoring:
                r = self.check(cam=cam)
                if r.get("intruders", 0) > 0: print(f"[ALERTA] Intruso! {r}")
                time.sleep(interval)
        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start(); print(f"[Intrusos] Monitoreo activo ({interval}s)")

    def stop_monitor(self):
        self._monitoring = False
        if self._thread: self._thread.join(timeout=2)
        print("[Intrusos] Monitoreo detenido.")

    def get_intrusions(self, limit: int = 50) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT timestamp, image_path, confidence, handled FROM intrusions ORDER BY timestamp DESC LIMIT ?", (limit,))
        intr = [{"ts": datetime.fromtimestamp(r[0]).isoformat(), "img": r[1], "conf": r[2], "handled": bool(r[3])} for r in c.fetchall()]
        conn.close(); return intr

    def mark_handled(self, iid: int) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("UPDATE intrusions SET handled=1 WHERE id=?", (iid,))
        conn.commit(); ok = c.rowcount > 0; conn.close(); return ok



# ============================================================
# SECCION 9: VAULT (#17)
# ============================================================

class MacronVault:
    """Caja fuerte cifrada AES-256-GCM para datos sensibles."""

    def __init__(self):
        MacronConfig.init_db()

    def _derive(self, pwd: str, salt: bytes) -> bytes:
        import hashlib
        return hashlib.pbkdf2_hmac("sha256", pwd.encode(), salt, 100000, dklen=32)

    def setup(self, pwd: str) -> Dict:
        salt = os.urandom(16)
        key = self._derive(pwd, salt)
        verif = hashlib.sha256(key).hexdigest()
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("INSERT OR REPLACE INTO vault (key, encrypted_value, salt, created) VALUES (?,?,?,?)",
                 ("__vault_setup__", verif, salt.hex(), time.time()))
        conn.commit(); conn.close()
        return {"success": True}

    def _verify(self, pwd: str) -> bool:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT encrypted_value, salt FROM vault WHERE key='__vault_setup__'")
        r = c.fetchone(); conn.close()
        if not r: return False
        return hashlib.sha256(self._derive(pwd, bytes.fromhex(r[1]))).hexdigest() == r[0]

    def store(self, key: str, value: str, pwd: str) -> Dict:
        if not self._verify(pwd):
            return {"success": False, "error": "Password incorrecto"}
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
            salt = os.urandom(16)
            dk = self._derive(pwd, salt)
            aes = AESGCM(dk)
            nonce = os.urandom(12)
            ct = aes.encrypt(nonce, value.encode(), None)
            pkg = salt + nonce + ct
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("INSERT OR REPLACE INTO vault (key, encrypted_value, salt, created) VALUES (?,?,?,?)",
                     (key, pkg.hex(), "", time.time()))
            conn.commit(); conn.close()
            return {"success": True, "key": key}
        except ImportError:
            return {"success": False, "error": "pip install cryptography"}

    def retrieve(self, key: str, pwd: str) -> Dict:
        if not self._verify(pwd):
            return {"success": False, "error": "Password incorrecto"}
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("SELECT encrypted_value FROM vault WHERE key=?", (key,))
            r = c.fetchone(); conn.close()
            if not r: return {"success": False, "error": "Clave no encontrada"}
            pkg = bytes.fromhex(r[0])
            salt, nonce, ct = pkg[:16], pkg[16:28], pkg[28:]
            dk = self._derive(pwd, salt)
            aes = AESGCM(dk)
            pt = aes.decrypt(nonce, ct, None)
            return {"success": True, "key": key, "value": pt.decode()}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def list_keys(self, pwd: str) -> List[str]:
        if not self._verify(pwd): return []
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT key FROM vault WHERE key!='__vault_setup__'")
        keys = [r[0] for r in c.fetchall()]; conn.close(); return keys

    def delete(self, key: str, pwd: str) -> bool:
        if not self._verify(pwd): return False
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("DELETE FROM vault WHERE key=?", (key,))
        conn.commit(); ok = c.rowcount > 0; conn.close(); return ok


# ============================================================
# SECCION 10: TRANSCRIPCION (#19)
# ============================================================

class MacronTranscription:
    """Transcripcion de audio con Whisper MLX (optimizado Apple Silicon)."""

    def __init__(self):
        MacronConfig.init_db()
        self.model = None
        self._load()

    def _load(self):
        if MacronConfig.HAS_MLX:
            try:
                import mlx_whisper
                self.model = "mlx"
                print("[Transcripcion] Whisper MLX activo")
            except ImportError:
                pass
        if self.model is None:
            try:
                import whisper
                size = "base" if MacronConfig.TOTAL_RAM_GB < 16 else "small" if MacronConfig.TOTAL_RAM_GB < 32 else "medium"
                self.model = whisper.load_model(size)
                print(f"[Transcripcion] Whisper {size} cargado")
            except ImportError:
                print("[Transcripcion] Instala: pip install openai-whisper")

    def transcribe(self, path: str, lang: Optional[str] = None) -> Dict:
        if not os.path.exists(path):
            return {"success": False, "error": "Archivo no encontrado"}
        if self.model is None:
            return {"success": False, "error": "Modelo no cargado"}
        try:
            t0 = time.time()
            if self.model == "mlx":
                import mlx_whisper
                r = mlx_whisper.transcribe(path, language=lang, path_or_hf_repo="mlx-community/whisper-large-v3-mlx")
            else:
                r = self.model.transcribe(path, language=lang)
            text = r.get("text", "").strip()
            segs = r.get("segments", [])
            dur = segs[-1]["end"] if segs else 0
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("INSERT INTO transcriptions (audio_path, text, language, duration, created) VALUES (?,?,?,?,?)",
                     (path, text, lang or r.get("language", "auto"), dur, time.time()))
            conn.commit(); conn.close()
            return {"success": True, "text": text, "lang": lang or r.get("language", "unknown"), "dur": dur, "time": time.time()-t0}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def from_mic(self, dur: int = 10, lang: Optional[str] = None) -> Dict:
        try:
            import sounddevice as sd, numpy as np, scipy.io.wavfile as wav
            print(f"[Transcripcion] Grabando {dur}s...")
            sr = 16000
            rec = sd.rec(int(dur*sr), samplerate=sr, channels=1, dtype=np.float32)
            sd.wait()
            tf = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
            wav.write(tf.name, sr, rec); tf.close()
            r = self.transcribe(tf.name, lang)
            os.unlink(tf.name); return r
        except ImportError:
            return {"success": False, "error": "pip install sounddevice scipy"}

    def list_transcriptions(self, limit: int = 50) -> List[Dict]:
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("SELECT audio_path, text, language, duration, created FROM transcriptions ORDER BY created DESC LIMIT ?", (limit,))
        txs = [{"audio": r[0], "text": r[1][:200]+"..." if len(r[1])>200 else r[1], "lang": r[2], "dur": r[3], "created": datetime.fromtimestamp(r[4]).isoformat()} for r in c.fetchall()]
        conn.close(); return txs


# ============================================================
# SECCION 11: AUTOCOMPLETADO DE CODIGO (#20)
# ============================================================

class MacronCodeCompletion:
    """Autocompletado con Qwen3-Coder via MLX."""

    def __init__(self):
        self.model = None
        self.tokenizer = None
        self._load()

    def _load(self):
        if MacronConfig.HAS_MLX:
            try:
                from mlx_lm import load
                self.model, self.tokenizer = load("mlx-community/Qwen3-Coder-1.7B-MLX")
                print("[CodeComplete] Qwen3-Coder MLX cargado")
            except ImportError:
                print("[CodeComplete] Instala: pip install mlx-lm")
        else:
            print("[CodeComplete] MLX no disponible")

    def complete(self, prompt: str, max_tokens: int = 128, temperature: float = 0.2) -> Dict:
        if self.model is None:
            return {"success": False, "error": "Modelo no cargado"}
        try:
            from mlx_lm import generate
            t0 = time.time()
            text = generate(self.model, self.tokenizer, prompt=prompt, max_tokens=max_tokens, temp=temperature, verbose=False)
            return {"success": True, "completion": text, "prompt": prompt, "time": time.time()-t0}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def suggest(self, code: str, language: str = "python") -> Dict:
        prompt = f"""# Language: {language}
# Complete the following code:

{code}
"""
        return self.complete(prompt, max_tokens=64, temperature=0.1)

    def explain(self, code: str, language: str = "python") -> Dict:
        prompt = f"""Explain this {language} code in Spanish:

```{language}
{code}
```

Explanation:
"""
        return self.complete(prompt, max_tokens=256, temperature=0.3)


# ============================================================
# SECCION 12: ORQUESTADOR CENTRAL
# ============================================================

class MacronOrchestrator:
    """Orquestador central - punto de entrada unico de MACRON."""

    def __init__(self):
        MacronConfig.init_db()
        self.rag = MacronRAG()
        self.planning = MacronPlanning()
        self.cot = MacronCoT()
        self.rutinas = MacronRutinas()
        self.face = MacronFaceRec()
        self.notion = MacronNotion()
        self.multi = MacronMultiDevice()
        self.intrusion = MacronIntrusion()
        self.vault = MacronVault()
        self.transcription = MacronTranscription()
        self.code = MacronCodeCompletion()
        print("=" * 50)
        print("  MACRON - Agente IA Local para macOS")
        print("  Version 2.0 | MAC NEO Optimizado")
        print("=" * 50)
        print(f"  Apple Silicon: {MacronConfig.IS_APPLE_SILICON}")
        print(f"  MLX:           {MacronConfig.HAS_MLX}")
        print(f"  MPS:           {MacronConfig.HAS_MPS}")
        print(f"  RAM:           {MacronConfig.TOTAL_RAM_GB:.1f} GB")
        print(f"  Modelo:        {MacronConfig.get_model_size()}")
        print("=" * 50)

    def status(self) -> Dict:
        return {
            "version": "2.0",
            "hardware": {
                "apple_silicon": MacronConfig.IS_APPLE_SILICON,
                "mlx": MacronConfig.HAS_MLX,
                "mps": MacronConfig.HAS_MPS,
                "ram_gb": round(MacronConfig.TOTAL_RAM_GB, 1),
                "model_size": MacronConfig.get_model_size()
            },
            "modules": {
                "rag": self.rag.embedder is not None,
                "planning": True,
                "cot": True,
                "rutinas": True,
                "face_rec": self.face.encoder is not None,
                "notion": self.notion.token is not None,
                "multi_device": True,
                "intrusion": True,
                "vault": True,
                "transcription": self.transcription.model is not None,
                "code_completion": self.code.model is not None
            }
        }

    def notify(self, title: str, message: str):
        if MacronConfig.IS_MACOS:
            subprocess.run(["osascript", "-e", f'display notification "{message}" with title "{title}"'])
        else:
            print(f"[NOTIFY] {title}: {message}")

    def log(self, level: str, message: str, module: str = "orchestrator"):
        conn = sqlite3.connect(str(MacronConfig.db_path()))
        c = conn.cursor()
        c.execute("INSERT INTO logs (level, message, module, timestamp) VALUES (?,?,?,?)",
                 (level, message, module, time.time()))
        conn.commit(); conn.close()


if __name__ == "__main__":
    macron = MacronOrchestrator()
    print("\nMACRON listo. Ejemplo:")
    print("  macron.rag.index_file('doc.pdf')")
    print("  macron.vault.setup('password')")
    print("  macron.rutinas.create('Backup', 'Backup diario', '0 2 * * *', 'shell', {'command': 'rsync ...'})")
