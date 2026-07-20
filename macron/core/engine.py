
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
