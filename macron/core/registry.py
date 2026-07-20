import os
import os

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
