#!/usr/bin/env python3
"""
MACRON_v30_MIGRATE.py
Migración automatizada v2.5 → v3.0 (Dual Brain)

MODOS:
    --dry-run     Simular sin cambios
    --migrate     Ejecutar migración real
    --verify      Verificar instalación
    --rollback    Restaurar v2.5

Uso:
    python3 MACRON_v30_MIGRATE.py --dry-run
    python3 MACRON_v30_MIGRATE.py --migrate
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

PROJECT_ROOT = Path(os.path.expanduser("~/Documents/MACRON"))

# ─── MÓDULOS EMBEBIDOS v3.0 ───

REGISTRY_PY = '''
import importlib
import inspect
import logging
from typing import Dict, Optional, List
from dataclasses import dataclass, field

logger = logging.getLogger(__name__)

@dataclass
class ModuleInfo:
    name: str
    module_path: str
    class_name: str
    version: str = "1.0"
    status: str = "unknown"
    error_msg: Optional[str] = None
    instance: Optional[object] = field(default=None, repr=False)
    dependencies: List[str] = field(default_factory=list)

class ModuleRegistry:
    def __init__(self):
        self._modules: Dict[str, ModuleInfo] = {}
        self._core = None
    def set_core(self, core):
        self._core = core
    def register(self, name, module_path, class_name, version="1.0", dependencies=None):
        info = ModuleInfo(name=name, module_path=module_path, class_name=class_name,
                          version=version, dependencies=dependencies or [])
        self._modules[name] = info
        return info
    def discover(self, package: str) -> int:
        count = 0
        try:
            pkg = importlib.import_module(package)
            pkg_path = os.path.dirname(pkg.__file__)
            for filename in os.listdir(pkg_path):
                if filename.startswith("_") or not filename.endswith(".py"):
                    continue
                module_name = filename[:-3]
                full_path = f"{package}.{module_name}"
                try:
                    mod = importlib.import_module(full_path)
                    for name, obj in inspect.getmembers(mod, inspect.isclass):
                        if hasattr(obj, "__macron_module__"):
                            self.register(name=getattr(obj, "__macron_name__", module_name),
                                          module_path=full_path, class_name=name,
                                          version=getattr(obj, "__version__", "1.0"),
                                          dependencies=getattr(obj, "__dependencies__", []))
                            count += 1
                except Exception as e:
                    logger.warning(f"No se pudo cargar {full_path}: {e}")
        except ImportError as e:
            logger.error(f"Paquete no encontrado: {package}: {e}")
        return count
    def load(self, name: str) -> Optional[object]:
        if name not in self._modules:
            return None
        info = self._modules[name]
        if info.instance is not None:
            return info.instance
        for dep in info.dependencies:
            if dep not in self._modules or self._modules[dep].status != "active":
                info.status = "error"
                info.error_msg = f"Dependencia faltante: {dep}"
                return None
        try:
            mod = importlib.import_module(info.module_path)
            cls = getattr(mod, info.class_name)
            sig = inspect.signature(cls.__init__)
            if "core" in sig.parameters and self._core is not None:
                instance = cls(self._core)
            else:
                instance = cls()
            info.instance = instance
            info.status = "active"
            return instance
        except Exception as e:
            info.status = "error"
            info.error_msg = str(e)
            return None
    def get(self, name: str) -> Optional[object]:
        if name not in self._modules:
            return None
        if self._modules[name].instance is None:
            return self.load(name)
        return self._modules[name].instance
    def unload(self, name: str) -> bool:
        if name in self._modules:
            self._modules[name].instance = None
            self._modules[name].status = "inactive"
            return True
        return False
    def list_modules(self, status: str = None):
        modules = list(self._modules.values())
        if status:
            modules = [m for m in modules if m.status == status]
        return modules
    def health_check(self):
        return {name: info.status for name, info in self._modules.items()}
    def __contains__(self, name: str) -> bool:
        return name in self._modules
    def __getitem__(self, name: str):
        return self.get(name)
'''

ENGINE_PY = '''
import logging
import os
from typing import Any, Dict, List, Optional
from pathlib import Path

from .registry import ModuleRegistry

logger = logging.getLogger(__name__)

class Config:
    def __init__(self, path=None):
        self._data = {
            "version": "3.0",
            "app_name": "MACRON",
            "debug": False,
            "log_level": "INFO",
            "data_dir": str(Path.home() / "Documents/MACRON"),
            "plugins_dir": str(Path.home() / "Documents/MACRON/plugins"),
            "cache_ttl": 5,
            "request_timeout": 30,
            "max_history": 100,
            "critical_modules": ["safari", "mail", "finder", "calendar", "notes", "reminders"],
            "ui": {"host": "127.0.0.1", "port": 5000, "theme": "dark"},
            "voice": {"enabled": True, "wake_word": "Hey MACRON", "language": "es-ES"},
            "security": {"encryption_enabled": True, "key_file": "~/.macron_key"},
            "agents": {
                "productivity": {"enabled": True, "schedule": "08:00"},
                "monitor": {"enabled": True, "interval_minutes": 60},
                "research": {"enabled": True, "max_results": 5},
                "conversation": {"enabled": True, "max_context": 100},
                "plugins": {"enabled": True}
            }
        }
    def get(self, key: str, default=None):
        keys = key.split(".")
        value = self._data
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        return value

class MacronEngine:
    _instance = None
    _initialized = False
    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    def __init__(self, config_path=None):
        if MacronEngine._initialized:
            return
        MacronEngine._initialized = True
        self.config = Config(config_path)
        self.registry = ModuleRegistry()
        self.registry.set_core(self)
        self._discover_modules()
        self._load_critical_modules()
        self._init_brain()
        logger.info(f"MACRON Engine v{self.config.get('version', '3.0')} iniciado")
    def _discover_modules(self):
        for pkg in ["macron.adapters", "macron.agents"]:
            try:
                count = self.registry.discover(pkg)
                logger.info(f"Descubiertos {count} modulos en {pkg}")
            except Exception as e:
                logger.warning(f"No se pudo descubrir {pkg}: {e}")
    def _load_critical_modules(self):
        for name in self.config.get("critical_modules", []):
            if self.registry.load(name):
                logger.info(f"Modulo critico cargado: {name}")
    def _init_brain(self):
        try:
            from ..infrastructure.brain import get_brain
            self.brain = get_brain(data_dir=self.config.get("data_dir"))
            logger.info("SecondBrain conectado")
        except Exception as e:
            logger.warning(f"SecondBrain no disponible: {e}")
            self.brain = None
    def __getattr__(self, name: str) -> Any:
        module = self.registry.get(name)
        if module is not None:
            return module
        raise AttributeError(f"MACRON no tiene modulo: {name}")
    def call(self, module: str, action: str, **kwargs) -> Dict:
        mod = self.registry.get(module)
        if mod is None:
            return {"success": False, "error": f"Modulo {module} no disponible"}
        method = getattr(mod, action, None)
        if method is None:
            return {"success": False, "error": f"Accion {action} no existe"}
        try:
            result = method(**kwargs)
            return {"success": True, "data": result, "module": module, "action": action}
        except Exception as e:
            logger.error(f"Error en {module}.{action}: {e}")
            return {"success": False, "error": str(e), "module": module, "action": action}
    def remember(self, content, source="system", category="observation", importance=1.0):
        if self.brain:
            return self.brain.remember(content, source, category, importance=importance)
        return None
    def recall(self, query, top_k=5, category=None):
        if self.brain:
            return self.brain.recall(query, top_k, category)
        return []
    def health(self) -> Dict:
        modules = self.registry.list_modules()
        return {
            "engine": "healthy",
            "version": self.config.get("version", "3.0"),
            "modules_total": len(modules),
            "modules_active": len([m for m in modules if m.status == "active"]),
            "modules_error": len([m for m in modules if m.status == "error"]),
            "registry": self.registry.health_check(),
        }
    def status(self) -> Dict:
        modules = self.registry.list_modules()
        return {
            "version": self.config.get("version", "3.0"),
            "modules": [{"name": m.name, "version": m.version, "status": m.status, "error": m.error_msg}
                        for m in modules]
        }

def get_engine(config_path=None):
    return MacronEngine(config_path)
'''

BASE_ADAPTER_PY = '''
import subprocess
import logging
import json
import time
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)

class AppleScriptResult:
    def __init__(self, stdout="", stderr="", returncode=0):
        self.stdout = stdout.strip()
        self.stderr = stderr.strip()
        self.returncode = returncode
        self.success = returncode == 0 and not stderr.strip()
    def json(self):
        try:
            return json.loads(self.stdout)
        except:
            return None
    def text(self):
        return self.stdout

class BaseAdapter(ABC):
    __macron_module__ = True
    __macron_name__ = "base"
    __version__ = "1.0"
    __dependencies__ = []
    __app_name__ = ""
    def __init__(self, core=None):
        self.core = core
        self.name = self.__macron_name__
        self.version = self.__version__
        self.logger = logging.getLogger(f"macron.adapters.{self.name}")
        self._cache = {}
        self._cache_ttl = 5
    def _script(self, action, **kwargs):
        return self._action_to_applescript(action, **kwargs)
    def _action_to_applescript(self, action, **kwargs):
        raise NotImplementedError(f"Accion '{action}' no implementada en {self.name}")
    def _run(self, script, timeout=30):
        self.logger.debug(f"Ejecutando: {script[:80]}...")
        try:
            result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, timeout=timeout)
            ar = AppleScriptResult(stdout=result.stdout, stderr=result.stderr, returncode=result.returncode)
            if not ar.success:
                self.logger.warning(f"AppleScript error: {ar.stderr}")
            return ar
        except subprocess.TimeoutExpired:
            return AppleScriptResult(stderr="Timeout", returncode=1)
        except FileNotFoundError:
            return AppleScriptResult(stderr="osascript not found", returncode=127)
        except Exception as e:
            return AppleScriptResult(stderr=str(e), returncode=1)
    def _check_app_running(self):
        script = f'tell application "System Events" to return (name of processes) contains "{self.__app_name__}"'
        result = self._run(script, timeout=5)
        return result.success and "true" in result.stdout.lower()
    def _ensure_app(self):
        if self._check_app_running():
            return True
        self.logger.info(f"Iniciando {self.__app_name__}...")
        script = f'tell application "{self.__app_name__}" to activate'
        result = self._run(script, timeout=10)
        return result.success
    def _cached(self, key, getter_func, ttl=None):
        now = time.time()
        ttl = ttl or self._cache_ttl
        if key in self._cache:
            value, timestamp = self._cache[key]
            if now - timestamp < ttl:
                return value
        value = getter_func()
        self._cache[key] = (value, now)
        return value
    def health(self):
        return {"name": self.name, "version": self.version, "app_running": self._check_app_running(),
                "app_name": self.__app_name__, "status": "healthy" if self._check_app_running() else "app_not_running"}
    @abstractmethod
    def info(self):
        pass
'''

BASE_AGENT_PY = '''
import logging
import json
import os
from abc import ABC, abstractmethod
from typing import Any, Dict
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)

class BaseAgent(ABC):
    __macron_module__ = True
    __macron_name__ = "base_agent"
    __version__ = "1.0"
    __dependencies__ = []
    _persist_dir = "~/Documents/MACRON/data"
    _max_history = 100
    def __init__(self, core=None):
        self.core = core
        self.name = self.__macron_name__
        self.version = self.__version__
        self.logger = logging.getLogger(f"macron.agents.{self.name}")
        self._data_dir = Path(os.path.expanduser(self._persist_dir))
        self._data_dir.mkdir(parents=True, exist_ok=True)
        self._memory_file = self._data_dir / f"{self.name}_memory.json"
        self._history_file = self._data_dir / f"{self.name}_history.json"
        self._memory = self._load_json(self._memory_file, default={})
        self._history = self._load_json(self._history_file, default=[])
        self._metrics = {"calls": 0, "errors": 0, "last_run": None}
    def _load_json(self, path, default=None):
        try:
            if path.exists():
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception as e:
            self.logger.warning(f"Error cargando {path}: {e}")
        return default or {}
    def _save_json(self, path, data):
        try:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            self.logger.error(f"Error guardando {path}: {e}")
        return False
    def _remember(self, key, value):
        self._memory[key] = {"value": value, "timestamp": datetime.now().isoformat()}
        return self._save_json(self._memory_file, self._memory)
    def _recall(self, key, default=None):
        entry = self._memory.get(key)
        return entry["value"] if entry else default
    def _log_action(self, action, result, error=None):
        entry = {"timestamp": datetime.now().isoformat(), "action": action, "success": error is None,
                 "result_summary": str(result)[:200] if result else None, "error": error}
        self._history.append(entry)
        if len(self._history) > self._max_history:
            self._history = self._history[-self._max_history:]
        self._save_json(self._history_file, self._history)
    def _execute(self, action, **kwargs):
        self._metrics["calls"] += 1
        self._metrics["last_run"] = datetime.now().isoformat()
        try:
            method = getattr(self, f"_do_{action}", None)
            if not method:
                raise AttributeError(f"Accion '{action}' no implementada")
            result = method(**kwargs)
            self._log_action(action, result)
            return {"success": True, "data": result, "agent": self.name}
        except Exception as e:
            self._metrics["errors"] += 1
            self.logger.error(f"Error en {action}: {e}", exc_info=True)
            self._log_action(action, None, str(e))
            return {"success": False, "error": str(e), "agent": self.name}
    def get_memory(self):
        return {"entries": len(self._memory), "history": len(self._history), "metrics": self._metrics,
                "memory_file": str(self._memory_file)}
    def clear_memory(self):
        self._memory = {}
        self._history = []
        self._save_json(self._memory_file, {})
        self._save_json(self._history_file, [])
        return True
    @abstractmethod
    def info(self):
        pass
    def health(self):
        total = max(self._metrics["calls"], 1)
        error_rate = self._metrics["errors"] / total
        return {"name": self.name, "version": self.version, "calls": self._metrics["calls"],
                "errors": self._metrics["errors"], "error_rate": error_rate,
                "memory_entries": len(self._memory), "history_entries": len(self._history),
                "status": "healthy" if error_rate < 0.1 else "degraded"}
'''

BRAIN_PY = '''
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
        summary_text = "\\n".join(summaries)
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
'''

SERVER_PY = '''
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import os
import logging

from ..core.engine import get_engine

logger = logging.getLogger(__name__)

def create_app(config=None):
    app = Flask(__name__, static_folder="../../ui/static", template_folder="../../ui/templates")
    CORS(app)
    engine = get_engine()
    @app.route("/api/health")
    def health():
        return jsonify(engine.health())
    @app.route("/api/status")
    def status():
        return jsonify(engine.status())
    @app.route("/api/<module>/<action>", methods=["POST"])
    def adapter_action(module, action):
        data = request.get_json() or {}
        return jsonify(engine.call(module, action, **data))
    @app.route("/api/agents/<agent>/<action>", methods=["POST"])
    def agent_action(agent, action):
        data = request.get_json() or {}
        mod = engine.registry.get(agent)
        if not mod:
            return jsonify({"success": False, "error": f"Agente {agent} no disponible"}), 404
        method = getattr(mod, action, None)
        if not method:
            return jsonify({"success": False, "error": f"Accion {action} no existe"}), 404
        try:
            return jsonify({"success": True, "data": method(**data)})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500
    @app.route("/api/chat", methods=["POST"])
    def chat():
        data = request.get_json() or {}
        message = data.get("message", "")
        agent = engine.registry.get("conversation")
        if agent:
            result = agent.generate_response(message)
            return jsonify(result)
        return jsonify({"text": "Agente no disponible", "error": True})
    @app.route("/api/plugins/list")
    def plugins_list():
        pm = engine.registry.get("plugin_manager")
        if pm:
            return jsonify({"plugins": pm.list_plugins(), "count": len(pm.list_plugins())})
        return jsonify({"plugins": [], "count": 0})
    @app.route("/api/plugins/run", methods=["POST"])
    def plugins_run():
        data = request.get_json() or {}
        pm = engine.registry.get("plugin_manager")
        if pm:
            return jsonify(pm.run_plugin(data.get("name"), data.get("args")))
        return jsonify({"error": "Plugin system no disponible"}), 500
    @app.route("/")
    def index():
        return send_from_directory("../../ui/templates", "index.html")
    @app.route("/static/<path:path>")
    def static_files(path):
        return send_from_directory("../../ui/static", path)
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="127.0.0.1", port=5000, debug=False)
'''

# ─── FUNCIONES DE MIGRACIÓN ───

def log(msg, level="INFO"):
    print(f"[{level}] {msg}")

def ensure_dir(path):
    Path(path).mkdir(parents=True, exist_ok=True)

def safe_write(path, content, dry_run=False):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if dry_run:
        action = "CREARIA" if not path.exists() else "SOBREESCRIBIRIA"
        print(f"  [{action}] {path.relative_to(PROJECT_ROOT)}")
        return
    if path.exists():
        old = path.read_text()
        if old.strip() == content.strip():
            return
    path.write_text(content)
    log(f"Escrito: {path.name}")

def find_latest_backup():
    backups = sorted([d for d in PROJECT_ROOT.iterdir() if d.name.startswith(".backup_v25_")])
    return backups[-1] if backups else None

def phase_backup(dry_run=False):
    log("FASE 1: BACKUP")
    if dry_run:
        backup_dir = PROJECT_ROOT / f".backup_v25_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        print(f"  [CREARIA] {backup_dir}")
        return True
    backup_dir = PROJECT_ROOT / f".backup_v25_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    ensure_dir(backup_dir)
    for f in PROJECT_ROOT.glob("*.py"):
        rel = f.relative_to(PROJECT_ROOT)
        dst = backup_dir / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dst)
    log(f"Backup en: {backup_dir}")
    return True

def phase_structure(dry_run=False):
    log("FASE 2: ESTRUCTURA")
    dirs = ["macron/core", "macron/adapters", "macron/agents", "macron/infrastructure", "macron/api",
            "ui/static/css", "ui/static/js", "ui/templates", "tests/unit", "tests/integration", "tests/e2e", "plugins", "scripts"]
    for d in dirs:
        if dry_run:
            status = "YA_EXISTE" if (PROJECT_ROOT / d).exists() else "CREARIA"
            print(f"  [{status}] {d}")
        else:
            ensure_dir(PROJECT_ROOT / d)
            init = PROJECT_ROOT / d / "__init__.py"
            if not init.exists():
                init.write_text("")
    if not dry_run:
        log("Estructura creada")
    return True

def phase_dependencies(dry_run=False):
    log("FASE 3: DEPENDENCIAS")
    deps = ["sentence-transformers", "faiss-cpu", "numpy", "pyyaml"]
    for dep in deps:
        try:
            __import__(dep.replace("-", "_").split(".")[0])
            status = "INSTALADO"
        except ImportError:
            status = "FALTA"
        print(f"  [{status}] {dep}")
        if not dry_run and status == "FALTA":
            log(f"Instalando {dep}...")
            subprocess.run([sys.executable, "-m", "pip", "install", dep], check=True)
    req = "flask>=2.0.0\\nflask-cors>=3.0.0\\npyyaml>=6.0.0\\nsentence-transformers>=2.2.0\\nfaiss-cpu>=1.7.0\\nnumpy>=1.24.0\\n"
    safe_write(PROJECT_ROOT / "requirements.txt", req, dry_run)
    return True

def phase_core(dry_run=False):
    log("FASE 4: CORE")
    safe_write(PROJECT_ROOT / "macron/core/registry.py", REGISTRY_PY, dry_run)
    safe_write(PROJECT_ROOT / "macron/core/engine.py", ENGINE_PY, dry_run)
    return True

def phase_infrastructure(dry_run=False):
    log("FASE 5: INFRAESTRUCTURA")
    safe_write(PROJECT_ROOT / "macron/infrastructure/brain.py", BRAIN_PY, dry_run)
    log("Infraestructura migrada")
    return True

def phase_adapters(dry_run=False):
    log("FASE 6: ADAPTERS")
    safe_write(PROJECT_ROOT / "macron/adapters/base.py", BASE_ADAPTER_PY, dry_run)
    return True

def phase_agents(dry_run=False):
    log("FASE 7: AGENTS")
    safe_write(PROJECT_ROOT / "macron/agents/base.py", BASE_AGENT_PY, dry_run)
    return True

def phase_ui(dry_run=False):
    log("FASE 8: UI")
    safe_write(PROJECT_ROOT / "macron/api/server.py", SERVER_PY, dry_run)
    return True

def phase_verify(dry_run=False):
    log("FASE 9: VERIFICACION")
    checks = [
        ("Engine", (PROJECT_ROOT / "macron/core/engine.py").exists()),
        ("Registry", (PROJECT_ROOT / "macron/core/registry.py").exists()),
        ("Brain", (PROJECT_ROOT / "macron/infrastructure/brain.py").exists()),
    ]
    all_ok = True
    for name, ok in checks:
        print(f"  [{'OK' if ok else 'FALTA'}] {name}")
        if not ok:
            all_ok = False
    return all_ok

def do_migrate(dry_run=False):
    print("=" * 60)
    print("MACRON v2.5 -> v3.0 MIGRACION" + (" (DRY-RUN)" if dry_run else ""))
    print("=" * 60)
    if not PROJECT_ROOT.exists():
        log("Proyecto no encontrado", "ERROR")
        return False
    phases = [phase_backup, phase_structure, phase_dependencies, phase_core, phase_infrastructure, phase_adapters, phase_agents, phase_ui, phase_verify]
    for phase in phases:
        try:
            if not phase(dry_run=dry_run):
                log("Fase fallo", "ERROR")
                return False
        except Exception as e:
            log(f"Error: {e}", "ERROR")
            import traceback
            traceback.print_exc()
            return False
    print("=" * 60)
    if dry_run:
        print("DRY-RUN COMPLETADO - Ningun archivo fue modificado")
    else:
        print("MIGRACION COMPLETADA")
    print("=" * 60)
    return True

def do_rollback():
    print("=" * 60)
    print("ROLLBACK v3.0 -> v2.5")
    print("=" * 60)
    backup = find_latest_backup()
    if not backup:
        log("No se encontro backup", "ERROR")
        return False
    log(f"Backup: {backup.name}")
    resp = input("Restaurar v2.5? Esto eliminara v3.0 (si/no): ")
    if resp.lower() != "si":
        log("Cancelado")
        return False
    for d in ["macron", "ui", "tests"]:
        path = PROJECT_ROOT / d
        if path.exists():
            shutil.rmtree(path)
            log(f"Eliminado: {d}")
    for f in ["config.yaml", "pytest.ini", "Makefile"]:
        path = PROJECT_ROOT / f
        if path.exists():
            path.unlink()
    for src in backup.rglob("*"):
        if src.is_file():
            rel = src.relative_to(backup)
            dst = PROJECT_ROOT / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    log("Rollback completado")
    return True

def do_verify():
    print("=" * 60)
    print("VERIFICACION MACRON v3.0")
    print("=" * 60)
    checks = [
        ("macron/core/engine.py", (PROJECT_ROOT / "macron/core/engine.py").exists()),
        ("macron/core/registry.py", (PROJECT_ROOT / "macron/core/registry.py").exists()),
        ("macron/infrastructure/brain.py", (PROJECT_ROOT / "macron/infrastructure/brain.py").exists()),
        ("macron/adapters/base.py", (PROJECT_ROOT / "macron/adapters/base.py").exists()),
        ("macron/agents/base.py", (PROJECT_ROOT / "macron/agents/base.py").exists()),
        ("macron/api/server.py", (PROJECT_ROOT / "macron/api/server.py").exists()),
    ]
    passed = sum(1 for _, ok in checks if ok)
    for name, ok in checks:
        print(f"  [{'OK' if ok else 'FALTA'}] {name}")
    print(f"\nResultado: {passed}/{len(checks)}")
    if passed == len(checks):
        print("MACRON v3.0 esta configurado")
    return passed == len(checks)

# ─── MAIN ───

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 MACRON_v30_MIGRATE.py [--dry-run|--migrate|--verify|--rollback]")
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "--dry-run":
        do_migrate(dry_run=True)
    elif cmd == "--migrate":
        do_migrate(dry_run=False)
    elif cmd == "--verify":
        do_verify()
    elif cmd == "--rollback":
        do_rollback()
    else:
        print(f"Comando desconocido: {cmd}")
        print("Uso: python3 MACRON_v30_MIGRATE.py [--dry-run|--migrate|--verify|--rollback]")
        sys.exit(1)

if __name__ == "__main__":
    main()
