"""
macron/adapters/base.py
BaseAdapter para MACRON v3.0
"""
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
    
    def _escape_applescript(self, text):
        """Escapa caracteres peligrosos en AppleScript."""
        if not isinstance(text, str):
            text = str(text)
        text = text.replace('"', '\\"')
        text = text.replace('\\', '\\\\')
        text = text.replace('\n', ' ')
        text = text.replace('\r', ' ')
        max_len = 5000
        if len(text) > max_len:
            text = text[:max_len] + '... [truncado]'
        return text
    
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
