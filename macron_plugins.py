"""
MACRON Plugins v1.0
Sistema de plugins para extender funcionalidades
"""
import os
import sys
import importlib.util
import json

PLUGINS_DIR = os.path.expanduser("~/Documents/MACRON/plugins")

def ensure_plugins_dir():
    os.makedirs(PLUGINS_DIR, exist_ok=True)

def load_plugin(plugin_file):
    """Carga un plugin desde archivo"""
    plugin_name = os.path.basename(plugin_file).replace(".py", "")
    spec = importlib.util.spec_from_file_location(plugin_name, plugin_file)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def list_plugins():
    """Lista plugins disponibles"""
    ensure_plugins_dir()
    plugins = []
    for f in os.listdir(PLUGINS_DIR):
        if f.endswith(".py") and not f.startswith("_"):
            plugins.append(f.replace(".py", ""))
    return plugins

def get_plugin_info(plugin_name):
    """Obtiene información de un plugin"""
    plugin_file = os.path.join(PLUGINS_DIR, f"{plugin_name}.py")
    if not os.path.exists(plugin_file):
        return None
    
    try:
        module = load_plugin(plugin_file)
        return {
            "name": getattr(module, "PLUGIN_NAME", plugin_name),
            "version": getattr(module, "PLUGIN_VERSION", "1.0"),
            "description": getattr(module, "PLUGIN_DESCRIPTION", ""),
            "author": getattr(module, "PLUGIN_AUTHOR", "Unknown")
        }
    except Exception as e:
        return {"error": str(e)}

def execute_plugin(plugin_name, *args, **kwargs):
    """Ejecuta un plugin"""
    plugin_file = os.path.join(PLUGINS_DIR, f"{plugin_name}.py")
    if not os.path.exists(plugin_file):
        return {"error": "Plugin no encontrado"}
    
    try:
        module = load_plugin(plugin_file)
        if hasattr(module, "run"):
            return module.run(*args, **kwargs)
        return {"error": "Plugin no tiene funcion run()"}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    ensure_plugins_dir()
    print(f"Plugins disponibles: {list_plugins()}")
    print(f"Directorio: {PLUGINS_DIR}")
