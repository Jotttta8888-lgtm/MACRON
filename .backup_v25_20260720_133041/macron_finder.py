"""
macron_finder.py
Integracion con Finder para MACRON v7.3
Funcionalidades: listar archivos, buscar, recientes, abrir, info
"""
import os
import subprocess
import json
from datetime import datetime

def _run_applescript(script):
    """Ejecuta AppleScript y devuelve stdout."""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return {"error": result.stderr.strip()}
        return {"success": True, "output": result.stdout.strip()}
    except Exception as e:
        return {"error": str(e)}

def get_desktop_files():
    """Lista archivos del escritorio."""
    desktop = os.path.expanduser("~/Desktop")
    try:
        files = []
        for name in os.listdir(desktop):
            path = os.path.join(desktop, name)
            stat = os.stat(path)
            files.append({
                "name": name,
                "path": path,
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "is_dir": os.path.isdir(path)
            })
        return sorted(files, key=lambda x: x["modified"], reverse=True)
    except Exception as e:
        return []

def get_downloads():
    """Lista archivos de Downloads."""
    downloads = os.path.expanduser("~/Downloads")
    try:
        files = []
        for name in os.listdir(downloads):
            path = os.path.join(downloads, name)
            stat = os.stat(path)
            files.append({
                "name": name,
                "path": path,
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "is_dir": os.path.isdir(path)
            })
        return sorted(files, key=lambda x: x["modified"], reverse=True)
    except Exception as e:
        return []

def search_files(query, path=None, limit=20):
    """Busca archivos por nombre en una ruta."""
    if path is None:
        path = os.path.expanduser("~")
    results = []
    try:
        for root, dirs, files in os.walk(path):
            # Ignorar carpetas ocultas y del sistema
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['Library', 'System', 'node_modules', 'venv', '__pycache__']]
            for name in files:
                if query.lower() in name.lower():
                    full_path = os.path.join(root, name)
                    stat = os.stat(full_path)
                    results.append({
                        "name": name,
                        "path": full_path,
                        "size": stat.st_size,
                        "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
                    })
                    if len(results) >= limit:
                        return results
        return results
    except Exception as e:
        return []

def get_recent_files(limit=10):
    """Obtiene archivos recientemente abiertos usando mdls."""
    try:
        # Usar mdfind para encontrar archivos recientes
        result = subprocess.run(
            ["mdfind", "-onlyin", os.path.expanduser("~"), "kMDItemLastUsedDate >= $time.today"],
            capture_output=True, text=True, timeout=10
        )
        files = []
        for line in result.stdout.strip().split("\n")[:limit]:
            if line and os.path.exists(line):
                stat = os.stat(line)
                files.append({
                    "name": os.path.basename(line),
                    "path": line,
                    "size": stat.st_size,
                    "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
                })
        return files
    except Exception as e:
        return []

def open_file(path):
    """Abre archivo con la app por defecto."""
    try:
        subprocess.run(["open", path], check=True, timeout=10)
        return {"success": True, "path": path}
    except Exception as e:
        return {"success": False, "error": str(e)}

def reveal_in_finder(path):
    """Muestra archivo en Finder."""
    try:
        subprocess.run(["open", "-R", path], check=True, timeout=10)
        return {"success": True, "path": path}
    except Exception as e:
        return {"success": False, "error": str(e)}

def get_file_info(path):
    """Obtiene informacion detallada de un archivo."""
    try:
        stat = os.stat(path)
        return {
            "name": os.path.basename(path),
            "path": path,
            "size": stat.st_size,
            "size_human": _human_size(stat.st_size),
            "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
            "is_dir": os.path.isdir(path),
            "exists": os.path.exists(path),
            "extension": os.path.splitext(path)[1]
        }
    except Exception as e:
        return {"error": str(e)}

def _human_size(size):
    """Convierte bytes a formato humano."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} PB"

# ── CLI TEST ────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Finder Integration v7.3")
    print("=" * 50)
    
    print("\n📁 DESKTOP:")
    for f in get_desktop_files()[:5]:
        icon = "📂" if f["is_dir"] else "📄"
        print(f"   {icon} {f['name'][:40]} ({_human_size(f['size'])})")
    
    print("\n📥 DOWNLOADS:")
    for f in get_downloads()[:5]:
        icon = "📂" if f["is_dir"] else "📄"
        print(f"   {icon} {f['name'][:40]} ({_human_size(f['size'])})")
    
    print("\n🔍 BUSCAR 'MACRON':")
    results = search_files("MACRON", limit=5)
    for r in results:
        print(f"   📄 {r['name'][:50]}")
        print(f"      {r['path'][:60]}")
    
    print("\n🕐 RECIENTES:")
    for f in get_recent_files(5):
        print(f"   📄 {f['name'][:50]}")
    
    print("\n" + "=" * 50)
    print("Finder Integration listo")
    print("=" * 50)
