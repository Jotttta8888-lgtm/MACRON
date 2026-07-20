"""
macron/adapters/finder.py
FinderAdapter para MACRON v3.0 - Hereda de BaseAdapter
"""
import os
import subprocess
from datetime import datetime
from .base import BaseAdapter

class FinderAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "finder"
    __version__ = "3.0"
    __dependencies__ = []
    __app_name__ = "Finder"
    
    def __init__(self, core=None):
        super().__init__(core)
    
    def _action_to_applescript(self, action, **kwargs):
        """Finder usa subprocess directo, no AppleScript."""
        raise NotImplementedError("FinderAdapter usa subprocess directo")
    
    def _human_size(self, size):
        """Convierte bytes a formato humano."""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} PB"
    
    def get_desktop_files(self):
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
                    "size_human": self._human_size(stat.st_size),
                    "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    "is_dir": os.path.isdir(path)
                })
            return sorted(files, key=lambda x: x["modified"], reverse=True)
        except Exception as e:
            return []
    
    def get_downloads(self):
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
                    "size_human": self._human_size(stat.st_size),
                    "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    "is_dir": os.path.isdir(path)
                })
            return sorted(files, key=lambda x: x["modified"], reverse=True)
        except Exception as e:
            return []
    
    def search_files(self, query, path=None, limit=20):
        """Busca archivos por nombre."""
        if path is None:
            path = os.path.expanduser("~")
        results = []
        try:
            for root, dirs, files in os.walk(path):
                dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['Library', 'System', 'node_modules', 'venv', '__pycache__']]
                for name in files:
                    if query.lower() in name.lower():
                        full_path = os.path.join(root, name)
                        stat = os.stat(full_path)
                        results.append({
                            "name": name,
                            "path": full_path,
                            "size": stat.st_size,
                            "size_human": self._human_size(stat.st_size),
                            "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
                        })
                        if len(results) >= limit:
                            return results
            return results
        except Exception as e:
            return []
    
    def get_recent_files(self, limit=10):
        """Obtiene archivos recientemente abiertos."""
        try:
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
                        "size_human": self._human_size(stat.st_size),
                        "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
                    })
            return files
        except Exception as e:
            return []
    
    def open_file(self, path):
        """Abre archivo con app por defecto."""
        try:
            subprocess.run(["open", path], check=True, timeout=10)
            return {"success": True, "path": path}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def reveal_in_finder(self, path):
        """Muestra archivo en Finder."""
        try:
            subprocess.run(["open", "-R", path], check=True, timeout=10)
            return {"success": True, "path": path}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_file_info(self, path):
        """Obtiene informacion detallada de un archivo."""
        try:
            stat = os.stat(path)
            return {
                "name": os.path.basename(path),
                "path": path,
                "size": stat.st_size,
                "size_human": self._human_size(stat.st_size),
                "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "is_dir": os.path.isdir(path),
                "exists": os.path.exists(path),
                "extension": os.path.splitext(path)[1]
            }
        except Exception as e:
            return {"error": str(e)}
    
    def info(self):
        return {"name": self.name, "version": self.version, "app": "Finder", "methods": [
            "get_desktop_files", "get_downloads", "search_files", "get_recent_files",
            "open_file", "reveal_in_finder", "get_file_info"
        ]}
