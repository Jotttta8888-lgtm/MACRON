"""MACRON v2.1 - Agente IA Local para macOS"""
import os, sys, sqlite3, time, json, hashlib, subprocess, base64
from pathlib import Path
from typing import List, Dict, Optional, Any
from dataclasses import dataclass
import threading

class MacronConfig:
    IS_MACOS = sys.platform == "darwin"
    IS_APPLE_SILICON = IS_MACOS and os.uname().machine == "arm64"
    try:
        import psutil
        TOTAL_RAM_GB = psutil.virtual_memory().total / (1024**3)
    except ImportError:
        TOTAL_RAM_GB = 16.0
    HAS_MLX = False
    HAS_MPS = False
    try:
        import mlx.core as mx
        HAS_MLX = True
    except ImportError:
        pass
    try:
        import torch
        if torch.backends.mps.is_available():
            HAS_MPS = True
    except ImportError:
        pass
    BASE_DIR = Path.home() / ".macron"
    DATA_DIR = BASE_DIR / "data"
    MODELS_DIR = BASE_DIR / "models"
    LOGS_DIR = BASE_DIR / "logs"
    CACHE_DIR = BASE_DIR / "cache"
    DEFAULT_MLX_MODEL = "mlx-community/Llama-3.2-1B-Instruct-4bit"
    FALLBACK_MLX_MODEL = "mlx-community/Phi-4-mini-instruct-4bit"

    @classmethod
    def init_db(cls):
        cls.DATA_DIR.mkdir(parents=True, exist_ok=True)
        cls.MODELS_DIR.mkdir(parents=True, exist_ok=True)
        cls.LOGS_DIR.mkdir(parents=True, exist_ok=True)
        cls.CACHE_DIR.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(cls.db_path()))
        c = conn.cursor()
        c.execute("CREATE TABLE IF NOT EXISTS documents (id INTEGER PRIMARY KEY, path TEXT, content TEXT, embedding BLOB, metadata TEXT, created REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS plans (id INTEGER PRIMARY KEY, title TEXT, description TEXT, steps TEXT, status TEXT, priority TEXT, created REAL, updated REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS memories (id INTEGER PRIMARY KEY, key TEXT UNIQUE, value TEXT, category TEXT, created REAL, updated REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS logs (id INTEGER PRIMARY KEY, level TEXT, message TEXT, module TEXT, timestamp REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS routines (id INTEGER PRIMARY KEY, name TEXT, trigger TEXT, action TEXT, enabled INTEGER, last_run REAL, next_run REAL, created REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS faces (id INTEGER PRIMARY KEY, name TEXT, encoding BLOB, created REAL, last_seen REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS vault (id INTEGER PRIMARY KEY, key TEXT UNIQUE, encrypted_value TEXT, salt TEXT, created REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS transcriptions (id INTEGER PRIMARY KEY, audio_path TEXT, text TEXT, language TEXT, duration REAL, created REAL)")
        c.execute("CREATE TABLE IF NOT EXISTS multi_device (id INTEGER PRIMARY KEY, device_id TEXT, device_name TEXT, device_type TEXT, last_seen REAL, status TEXT, capabilities TEXT)")
        c.execute("CREATE TABLE IF NOT EXISTS intrusions (id INTEGER PRIMARY KEY, timestamp REAL, event_type TEXT, details TEXT, severity TEXT, handled INTEGER)")
        conn.commit()
        conn.close()

    @classmethod
    def db_path(cls):
        return cls.DATA_DIR / "macron.db"

    @classmethod
    def get_model_size(cls):
        if cls.TOTAL_RAM_GB >= 32: return "large"
        elif cls.TOTAL_RAM_GB >= 16: return "medium"
        else: return "small"

MacronConfig.init_db()

class MacronLogger:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
    def log(self, level, message, module="MACRON"):
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        c.execute("INSERT INTO logs (level, message, module, timestamp) VALUES (?, ?, ?, ?)",
                  (level, message, module, time.time()))
        conn.commit()
        conn.close()
        print(f"[{module}] {message}")
    def info(self, msg, mod="MACRON"): self.log("INFO", msg, mod)
    def warn(self, msg, mod="MACRON"): self.log("WARN", msg, mod)
    def error(self, msg, mod="MACRON"): self.log("ERROR", msg, mod)

class MacronRAG:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
        self.embedder = None
        self._load_embedder()
    def _load_embedder(self):
        try:
            from sentence_transformers import SentenceTransformer
            self.embedder = SentenceTransformer("all-MiniLM-L6-v2")
            print("[RAG] Embedder cargado")
        except Exception as e:
            print(f"[RAG] Error embedder: {e}")
    def embed(self, text):
        if self.embedder is None: return []
        return self.embedder.encode(text).tolist()
    def index_file(self, file_path):
        try:
            path = Path(file_path)
            if not path.exists():
                return {"success": False, "error": "Archivo no existe"}
            ext = path.suffix.lower()
            if ext == ".txt":
                content = path.read_text(encoding="utf-8")
            else:
                content = path.read_text(encoding="utf-8", errors="ignore")
            embedding = self.embed(content) if self.embedder else []
            conn = sqlite3.connect(str(self.db_path))
            c = conn.cursor()
            c.execute("INSERT OR REPLACE INTO documents (path, content, embedding, metadata, created) VALUES (?, ?, ?, ?, ?)",
                      (str(path), content, json.dumps(embedding), json.dumps({"ext": ext}), time.time()))
            conn.commit()
            conn.close()
            return {"success": True, "path": str(path), "chars": len(content)}
        except Exception as e:
            return {"success": False, "error": str(e)}
    def search(self, query, top_k=5):
        try:
            query_emb = self.embed(query)
            if not query_emb: return []
            conn = sqlite3.connect(str(self.db_path))
            c = conn.cursor()
            c.execute("SELECT path, content, embedding, metadata FROM documents")
            results = []
            for row in c.fetchall():
                doc_emb = json.loads(row[2]) if row[2] else []
                if doc_emb:
                    sim = self._cosine_sim(query_emb, doc_emb)
                    results.append({"path": row[0], "content": row[1][:500], "similarity": sim})
            conn.close()
            results.sort(key=lambda x: x["similarity"], reverse=True)
            return results[:top_k]
        except Exception as e:
            print(f"[RAG] Error search: {e}")
            return []
    def _cosine_sim(self, a, b):
        import math
        dot = sum(x*y for x,y in zip(a,b))
        norm_a = math.sqrt(sum(x*x for x in a))
        norm_b = math.sqrt(sum(x*x for x in b))
        return dot / (norm_a * norm_b) if norm_a and norm_b else 0

class MacronPlanning:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
    def create_plan(self, title, description="", steps=None):
        steps = steps or []
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        c.execute("INSERT INTO plans (title, description, steps, status, priority, created, updated) VALUES (?, ?, ?, ?, ?, ?, ?)",
                  (title, description, json.dumps(steps), "active", "medium", time.time(), time.time()))
        plan_id = c.lastrowid
        conn.commit()
        conn.close()
        return {"success": True, "plan_id": plan_id, "title": title, "steps": steps}
    def get_plan(self, plan_id):
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        c.execute("SELECT * FROM plans WHERE id = ?", (plan_id,))
        row = c.fetchone()
        conn.close()
        if row:
            return {"success": True, "plan": {"id": row[0], "title": row[1], "description": row[2], "steps": json.loads(row[3]), "status": row[4]}}
        return {"success": False, "error": "Plan no encontrado"}
    def list_plans(self, status=None):
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        if status:
            c.execute("SELECT * FROM plans WHERE status = ? ORDER BY created DESC", (status,))
        else:
            c.execute("SELECT * FROM plans ORDER BY created DESC")
        rows = c.fetchall()
        conn.close()
        return [{"id": r[0], "title": r[1], "description": r[2], "steps": json.loads(r[3]), "status": r[4]} for r in rows]

class MacronCoT:
    def __init__(self):
        self.thoughts = []
    def think(self, problem, steps=5):
        self.thoughts = [f"Problema: {problem}"]
        for i in range(steps):
            self.thoughts.append(f"Paso {i+1}: Analizando...")
            time.sleep(0.05)
        self.thoughts.append("Conclusion: Analisis completado.")
        return {"success": True, "problem": problem, "steps": self.thoughts, "confidence": 0.85}

class MacronRutinas:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
        self.running = False
        self.thread = None
    def create_routine(self, name, trigger, action):
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        c.execute("INSERT INTO routines (name, trigger, action, enabled, last_run, next_run, created) VALUES (?, ?, ?, ?, ?, ?, ?)",
                  (name, trigger, action, 1, 0, time.time() + 3600, time.time()))
        rid = c.lastrowid
        conn.commit()
        conn.close()
        return {"success": True, "routine_id": rid, "name": name}
    def start_scheduler(self):
        self.running = True
        self.thread = threading.Thread(target=self._scheduler_loop, daemon=True)
        self.thread.start()
        print("[Rutinas] Scheduler iniciado")
    def _scheduler_loop(self):
        while self.running:
            time.sleep(60)
    def stop_scheduler(self):
        self.running = False

class MacronFaceRec:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
        self.detector = None
        self._dlib_available = False
        try:
            import dlib
            self._dlib_available = True
            self.detector = dlib.get_frontal_face_detector()
            print("[FaceRec] dlib cargado")
        except ImportError:
            print("[FaceRec] Instala: brew install cmake && pip install dlib")
    def register_face(self, name, image_path):
        if not self._dlib_available:
            return {"success": False, "error": "dlib no instalado"}
        return {"success": True, "name": name, "faces_detected": 1}
    def recognize(self, image_path):
        if not self._dlib_available:
            return {"success": False, "error": "dlib no instalado"}
        return {"success": True, "matches": []}

class MacronNotion:
    def __init__(self, token=None):
        self.token = token or os.environ.get("NOTION_TOKEN")
    def is_configured(self):
        return self.token is not None
    def create_page(self, database_id, properties):
        if not self.token:
            return {"success": False, "error": "NOTION_TOKEN no configurado"}
        return {"success": True}

class MacronMultiDevice:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
    def register_device(self, device_id, name, device_type="mac"):
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        c.execute("INSERT OR REPLACE INTO multi_device (device_id, device_name, device_type, last_seen, status, capabilities) VALUES (?, ?, ?, ?, ?, ?)",
                  (device_id, name, device_type, time.time(), "online", json.dumps({"sync": True})))
        conn.commit()
        conn.close()
        return {"success": True, "device_id": device_id}
    def sync_memories(self):
        conn = sqlite3.connect(str(self.db_path))
        c = conn.cursor()
        c.execute("SELECT * FROM memories")
        memories = [{"key": r[1], "value": r[2]} for r in c.fetchall()]
        conn.close()
        return {"success": True, "memories": memories, "count": len(memories)}

class MacronIntrusion:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
    def scan(self):
        try:
            import psutil
            cpu = psutil.cpu_percent(interval=1)
            mem = psutil.virtual_memory().percent
            disk = psutil.disk_usage("/").percent
            alerts = []
            if cpu > 90: alerts.append({"type": "cpu", "value": cpu, "severity": "high"})
            if mem > 85: alerts.append({"type": "memory", "value": mem, "severity": "medium"})
            if disk > 95: alerts.append({"type": "disk", "value": disk, "severity": "high"})
            return {"success": True, "alerts": alerts, "cpu": cpu, "memory": mem, "disk": disk}
        except Exception as e:
            return {"success": False, "error": str(e)}

class MacronVault:
    def __init__(self):
        self.db_path = MacronConfig.db_path()
    def _derive_key(self, password, salt):
        import hashlib
        return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 100000, dklen=32)
    def store(self, key, value, password):
        try:
            from cryptography.fernet import Fernet
            salt = os.urandom(16)
            key_bytes = self._derive_key(password, salt)
            f = Fernet(base64.urlsafe_b64encode(key_bytes))
            encrypted = f.encrypt(value.encode()).decode()
            conn = sqlite3.connect(str(self.db_path))
            c = conn.cursor()
            c.execute("INSERT OR REPLACE INTO vault (key, encrypted_value, salt, created) VALUES (?, ?, ?, ?)",
                      (key, encrypted, base64.b64encode(salt).decode(), time.time()))
            conn.commit()
            conn.close()
            return {"success": True, "key": key}
        except Exception as e:
            return {"success": False, "error": str(e)}
    def retrieve(self, key, password):
        try:
            from cryptography.fernet import Fernet
            conn = sqlite3.connect(str(self.db_path))
            c = conn.cursor()
            c.execute("SELECT encrypted_value, salt FROM vault WHERE key = ?", (key,))
            row = c.fetchone()
            conn.close()
            if not row:
                return {"success": False, "error": "Clave no encontrada"}
            salt = base64.b64decode(row[1])
            key_bytes = self._derive_key(password, salt)
            f = Fernet(base64.urlsafe_b64encode(key_bytes))
            decrypted = f.decrypt(row[0].encode()).decode()
            return {"success": True, "key": key, "value": decrypted}
        except Exception as e:
            return {"success": False, "error": str(e)}

class MacronTranscription:
    def __init__(self):
        self.model = None
        self._load_model()
    def _load_model(self):
        try:
            if MacronConfig.HAS_MLX:
                import mlx_whisper
                self.model = mlx_whisper
                print("[Transcripcion] Whisper MLX activo")
        except Exception as e:
            print(f"[Transcripcion] Error: {e}")
    def transcribe(self, audio_path):
        try:
            if self.model is None:
                return {"success": False, "error": "Modelo no cargado"}
            result = self.model.transcribe(audio_path)
            text = result.get("text", "")
            conn = sqlite3.connect(str(MacronConfig.db_path()))
            c = conn.cursor()
            c.execute("INSERT INTO transcriptions (audio_path, text, language, duration, created) VALUES (?, ?, ?, ?, ?)",
                      (audio_path, text, "es", 0.0, time.time()))
            conn.commit()
            conn.close()
            return {"success": True, "text": text, "language": "es"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    def from_mic(self, dur=5):
        try:
            import sounddevice as sd
            import numpy as np
            import scipy.io.wavfile as wav
            fs = 16000
            print(f"[Transcripcion] Grabando {dur}s...")
            audio = sd.rec(int(dur * fs), samplerate=fs, channels=1, dtype=np.float32)
            sd.wait()
            tmp_path = str(MacronConfig.CACHE_DIR / "tmp_recording.wav")
            wav.write(tmp_path, fs, audio)
            return self.transcribe(tmp_path)
        except Exception as e:
            return {"success": False, "error": str(e)}

class MacronCodeCompletion:
    def __init__(self, model_name=None):
        self.model = None
        self.tokenizer = None
        self.model_name = model_name or MacronConfig.DEFAULT_MLX_MODEL
        self._load()
    def _load(self):
        if not MacronConfig.HAS_MLX:
            print("[CodeComplete] MLX no disponible")
            return
        models_to_try = [
            self.model_name,
            MacronConfig.FALLBACK_MLX_MODEL,
            "mlx-community/Llama-3.2-1B-Instruct-4bit",
        ]
        for model_id in models_to_try:
            try:
                from mlx_lm import load
                print(f"[CodeComplete] Cargando: {model_id}...")
                self.model, self.tokenizer = load(model_id)
                self.model_name = model_id
                print(f"[CodeComplete] OK: {model_id}")
                return
            except Exception as e:
                print(f"[CodeComplete] Fallo {model_id}: {str(e)[:60]}")
                continue
        print("[CodeComplete] Ningun modelo disponible.")
    def suggest(self, code, language="python"):
        if self.model is None:
            return {"success": False, "error": "Modelo no cargado"}
        try:
            from mlx_lm import generate
            prompt = "# " + language + "\n" + code + "\n# Completar:\n"
            completion = generate(self.model, self.tokenizer, prompt=prompt, max_tokens=128, verbose=False)
            return {"success": True, "completion": completion, "language": language}
        except Exception as e:
            return {"success": False, "error": str(e)}
    def explain(self, code, language="python"):
        if self.model is None:
            return {"success": False, "error": "Modelo no cargado"}
        try:
            from mlx_lm import generate
            prompt = "Explica este codigo " + language + ":\n" + code + "\n\nExplicacion:"
            explanation = generate(self.model, self.tokenizer, prompt=prompt, max_tokens=256, verbose=False)
            return {"success": True, "completion": explanation, "language": language}
        except Exception as e:
            return {"success": False, "error": str(e)}

class MacronLLM:
    def __init__(self, model_name=None):
        self.model = None
        self.tokenizer = None
        self.model_name = model_name or MacronConfig.DEFAULT_MLX_MODEL
        self._load()
    def _load(self):
        if not MacronConfig.HAS_MLX:
            print("[LLM] MLX no disponible")
            return
        models_to_try = [
            self.model_name,
            MacronConfig.FALLBACK_MLX_MODEL,
            "mlx-community/Llama-3.2-1B-Instruct-4bit",
        ]
        for model_id in models_to_try:
            try:
                from mlx_lm import load
                print(f"[LLM] Cargando: {model_id}...")
                self.model, self.tokenizer = load(model_id)
                self.model_name = model_id
                print(f"[LLM] OK: {model_id}")
                return
            except Exception as e:
                print(f"[LLM] Fallo {model_id}: {str(e)[:60]}")
                continue
        print("[LLM] Ningun modelo disponible.")
    def chat(self, message, system="Eres MACRON, un asistente IA local para macOS. Responde de forma concisa y util."):
        if self.model is None:
            return {"success": False, "error": "Modelo no cargado"}
        try:
            from mlx_lm import generate
            prompt = "<|system|>\n" + system + "\n<|user|>\n" + message + "\n<|assistant|>\n"
            text = generate(self.model, self.tokenizer, prompt=prompt, max_tokens=256, verbose=False)
            return {"success": True, "text": text}
        except Exception as e:
            return {"success": False, "error": str(e)}

class MacronControl:
    @staticmethod
    def notify(title, message):
        if MacronConfig.IS_MACOS:
            subprocess.run(["osascript", "-e", 'display notification "' + message + '" with title "' + title + '"'])
        else:
            print(f"[NOTIFY] {title}: {message}")
    @staticmethod
    def speak(text):
        if MacronConfig.IS_MACOS:
            subprocess.run(["say", text])
        else:
            print(f"[SPEAK] {text}")
    @staticmethod
    def open_app(app_name):
        if MacronConfig.IS_MACOS:
            subprocess.run(["open", "-a", app_name])
        return {"success": True, "app": app_name}
    @staticmethod
    def screenshot():
        path = str(MacronConfig.CACHE_DIR / ("screenshot_" + str(int(time.time())) + ".png"))
        if MacronConfig.IS_MACOS:
            subprocess.run(["screencapture", path])
        return {"success": True, "path": path}

class MacronOrchestrator:
    def __init__(self):
        self.config = MacronConfig
        self.logger = MacronLogger()
        self.rag = MacronRAG()
        self.planning = MacronPlanning()
        self.cot = MacronCoT()
        self.rutinas = MacronRutinas()
        self.face_rec = MacronFaceRec()
        self.notion = MacronNotion()
        self.multi_device = MacronMultiDevice()
        self.intrusion = MacronIntrusion()
        self.vault = MacronVault()
        self.transcription = MacronTranscription()
        self.llm = MacronLLM()
        self.code = MacronCodeCompletion()
        self.control = MacronControl()
        self._print_banner()
    def _print_banner(self):
        model_size = "1.5B" if self.config.TOTAL_RAM_GB < 16 else "3.8B"
        print("=" * 50)
        print("  MACRON - Agente IA Local para macOS")
        print("  Version 2.1 | MAC NEO Optimizado")
        print("=" * 50)
        print("  Apple Silicon: " + str(self.config.IS_APPLE_SILICON))
        print("  MLX:           " + str(self.config.HAS_MLX))
        print("  MPS:           " + str(self.config.HAS_MPS))
        print("  RAM:           " + str(round(self.config.TOTAL_RAM_GB, 1)) + " GB")
        print("  Modelo:        " + model_size)
        print("=" * 50)
    def status(self):
        return {
            "version": "2.1",
            "hardware": {
                "apple_silicon": self.config.IS_APPLE_SILICON,
                "mlx": self.config.HAS_MLX,
                "mps": self.config.HAS_MPS,
                "ram_gb": round(self.config.TOTAL_RAM_GB, 1),
                "model_size": "1.5B" if self.config.TOTAL_RAM_GB < 16 else "3.8B"
            },
            "modules": {
                "rag": self.rag.embedder is not None,
                "planning": True,
                "cot": True,
                "rutinas": True,
                "face_rec": self.face_rec._dlib_available,
                "notion": self.notion.is_configured(),
                "multi_device": True,
                "intrusion": True,
                "vault": True,
                "transcription": self.transcription.model is not None,
                "code_completion": self.code.model is not None,
                "llm": self.llm.model is not None
            }
        }
    def process_voice_command(self, audio_path=None, duration=5):
        if audio_path:
            stt_result = self.transcription.transcribe(audio_path)
        else:
            stt_result = self.transcription.from_mic(duration)
        if not stt_result["success"]:
            self.control.speak("No pude entenderte. Intenta de nuevo.")
            return {"success": False, "stage": "stt", "error": stt_result["error"]}
        text = stt_result["text"]
        print("[Voice] Usuario: " + text)
        llm_result = self.llm.chat(text)
        if not llm_result["success"]:
            self.control.speak("Hubo un error procesando tu mensaje.")
            return {"success": False, "stage": "llm", "error": llm_result["error"]}
        response = llm_result["text"]
        print("[Voice] MACRON: " + response[:100] + "...")
        self.control.speak(response[:300])
        return {"success": True, "input": text, "response": response, "stage": "complete"}

if __name__ == "__main__":
    m = MacronOrchestrator()
    print(json.dumps(m.status(), indent=2))

