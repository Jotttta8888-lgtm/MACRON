"""
macron_plugins.py
Sistema de plugins para MACRON v8.4
Funcionalidades: cargar plugins, ejecutar, listar, gestionar
"""
import os
import sys
import json
import importlib.util
from datetime import datetime
from pathlib import Path

class PluginManager:
    """Gestiona plugins dinamicos para MACRON."""
    
    def __init__(self, core, plugins_dir=None):
        self.core = core
        self.name = "PluginManager"
        self.version = "1.0"
        self.plugins_dir = plugins_dir or os.path.expanduser("~/Documents/MACRON/plugins")
        self.loaded_plugins = {}
        self._ensure_plugins_dir()
    
    def _ensure_plugins_dir(self):
        """Crea el directorio de plugins si no existe."""
        p = Path(self.plugins_dir)
        if not p.exists():
            p.mkdir(parents=True, exist_ok=True)
            # Crear plugin de ejemplo
            self._create_example_plugin()
    
    def _create_example_plugin(self):
        """Crea un plugin de ejemplo."""
        example = '''"""
example_plugin.py
Plugin de ejemplo para MACRON
"""
class ExamplePlugin:
    def __init__(self, core):
        self.core = core
        self.name = "ExamplePlugin"
        self.version = "1.0"
    
    def run(self, args=None):
        """Ejecuta el plugin."""
        return {
            "success": True,
            "message": "Plugin de ejemplo ejecutado correctamente",
            "data": {"timestamp": str(datetime.now())}
        }
    
    def info(self):
        """Retorna informacion del plugin."""
        return {
            "name": self.name,
            "version": self.version,
            "description": "Plugin de ejemplo para MACRON",
            "author": "MACRON Team"
        }

def create_plugin(core):
    """Factory para crear instancia del plugin."""
    return ExamplePlugin(core)
'''
        example_path = Path(self.plugins_dir) / "example_plugin.py"
        with open(example_path, 'w') as f:
            f.write(example)
    
    def list_plugins(self):
        """Lista todos los plugins disponibles."""
        plugins = []
        p = Path(self.plugins_dir)
        if not p.exists():
            return plugins
        
        for f in p.glob("*.py"):
            if f.name.startswith("_"):
                continue
            plugins.append({
                "name": f.stem,
                "path": str(f),
                "size": f.stat().st_size
            })
        return plugins
    
    def load_plugin(self, plugin_name):
        """Carga un plugin dinamicamente."""
        try:
            plugin_path = Path(self.plugins_dir) / f"{plugin_name}.py"
            if not plugin_path.exists():
                return {"error": f"Plugin no encontrado: {plugin_name}"}
            
            spec = importlib.util.spec_from_file_location(plugin_name, str(plugin_path))
            module = importlib.util.module_from_spec(spec)
            sys.modules[plugin_name] = module
            spec.loader.exec_module(module)
            
            if hasattr(module, 'create_plugin'):
                instance = module.create_plugin(self.core)
                self.loaded_plugins[plugin_name] = instance
                return {
                    "success": True,
                    "plugin": plugin_name,
                    "info": instance.info() if hasattr(instance, 'info') else {}
                }
            else:
                return {"error": f"Plugin {plugin_name} no tiene funcion create_plugin"}
        except Exception as e:
            return {"error": str(e)}
    
    def run_plugin(self, plugin_name, args=None):
        """Ejecuta un plugin cargado."""
        if plugin_name in self.loaded_plugins:
            try:
                instance = self.loaded_plugins[plugin_name]
                if hasattr(instance, 'run'):
                    return instance.run(args)
                return {"error": f"Plugin {plugin_name} no tiene metodo run"}
            except Exception as e:
                return {"error": str(e)}
        
        # Intentar cargar y ejecutar
        load_result = self.load_plugin(plugin_name)
        if "error" in load_result:
            return load_result
        
        return self.run_plugin(plugin_name, args)
    
    def unload_plugin(self, plugin_name):
        """Descarga un plugin."""
        if plugin_name in self.loaded_plugins:
            del self.loaded_plugins[plugin_name]
            if plugin_name in sys.modules:
                del sys.modules[plugin_name]
            return {"success": True, "message": f"Plugin {plugin_name} descargado"}
        return {"error": f"Plugin {plugin_name} no estaba cargado"}
    
    def get_loaded_plugins(self):
        """Retorna lista de plugins cargados."""
        return [
            {
                "name": name,
                "info": instance.info() if hasattr(instance, 'info') else {}
            }
            for name, instance in self.loaded_plugins.items()
        ]

# -- CLI TEST --
if __name__ == "__main__":
    import sys
    sys.path.insert(0, '.')
    import macron_core
    
    print("=" * 50)
    print("MACRON Plugin System v8.4")
    print("=" * 50)
    
    core = macron_core.MacronCore()
    manager = PluginManager(core)
    
    print(f"\n📂 Directorio de plugins: {manager.plugins_dir}")
    
    print("\n📋 PLUGINS DISPONIBLES:")
    plugins = manager.list_plugins()
    for p in plugins:
        print(f"   • {p['name']} ({p['size']} bytes)")
    
    if plugins:
        print(f"\n🔌 CARGANDO PLUGIN: {plugins[0]['name']}")
        result = manager.load_plugin(plugins[0]['name'])
        print(f"   Resultado: {result.get('success', False)}")
        
        print(f"\n▶️ EJECUTANDO PLUGIN: {plugins[0]['name']}")
        run_result = manager.run_plugin(plugins[0]['name'])
        print(f"   {run_result.get('message', 'Sin mensaje')}")
    
    print("\n📦 PLUGINS CARGADOS:")
    loaded = manager.get_loaded_plugins()
    for p in loaded:
        print(f"   • {p['name']} v{p['info'].get('version', 'N/A')}")
    
    print("\n" + "=" * 50)
    print("Plugin System listo")
    print("=" * 50)
