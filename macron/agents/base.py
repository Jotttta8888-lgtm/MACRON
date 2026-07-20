
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

    def _get_adapter(self, name):
        """Obtiene un adapter del engine."""
        try:
            from macron.core.engine import get_engine
            engine = get_engine()
            return engine.registry.get(name)
        except Exception as e:
            return None

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
