"""
macron/agents/monitor.py
MonitorAgent para MACRON v3.0 - Hereda de BaseAgent
"""
import os
import time
import json
from datetime import datetime
from pathlib import Path
from .base import BaseAgent

class MonitorAgent(BaseAgent):
    __macron_module__ = True
    __macron_name__ = "monitor"
    __version__ = "3.0"
    __dependencies__ = ["finder"]
    
    def __init__(self, core=None):
        super().__init__(core)
        self.watch_paths = [
            os.path.expanduser("~/Downloads"),
            os.path.expanduser("~/Desktop")
        ]
    
    def scan_folder(self, path, limit=20):
        """Escanea carpeta y devuelve archivos recientes."""
        try:
            files = []
            p = Path(path)
            if not p.exists():
                return {"error": f"Carpeta no existe: {path}"}
            
            for f in p.iterdir():
                if f.is_file():
                    stat = f.stat()
                    files.append({
                        "name": f.name,
                        "path": str(f),
                        "size": stat.st_size,
                        "size_human": self._human_size(stat.st_size),
                        "modified": datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d %H:%M"),
                        "extension": f.suffix.lower()
                    })
            
            files.sort(key=lambda x: x["modified"], reverse=True)
            return {"path": path, "files": files[:limit], "count": len(files)}
        except Exception as e:
            return {"error": str(e)}
    
    def detect_large_files(self, path, min_size_mb=100):
        """Detecta archivos grandes."""
        try:
            large_files = []
            p = Path(path)
            if not p.exists():
                return {"error": f"Carpeta no existe: {path}"}
            
            for f in p.iterdir():
                if f.is_file():
                    size_mb = f.stat().st_size / (1024 * 1024)
                    if size_mb > min_size_mb:
                        large_files.append({
                            "name": f.name,
                            "size_mb": round(size_mb, 2),
                            "path": str(f)
                        })
            
            return {"path": path, "files": large_files, "count": len(large_files)}
        except Exception as e:
            return {"error": str(e)}
    
    def suggest_organization(self, path):
        """Sugiere organizacion por tipo."""
        try:
            suggestions = []
            p = Path(path)
            if not p.exists():
                return {"error": f"Carpeta no existe: {path}"}
            
            by_type = {}
            for f in p.iterdir():
                if f.is_file():
                    ext = f.suffix.lower() or "sin_extension"
                    by_type[ext] = by_type.get(ext, 0) + 1
            
            for ext, count in by_type.items():
                if count > 3:
                    folder_name = ext.replace(".", "").upper() + "_files"
                    suggestions.append({
                        "extension": ext,
                        "count": count,
                        "suggested_folder": folder_name,
                        "action": f"Mover {count} archivos {ext} a carpeta {folder_name}/"
                    })
            
            return {"path": path, "suggestions": suggestions, "total_types": len(by_type)}
        except Exception as e:
            return {"error": str(e)}
    
    def full_report(self):
        """Genera reporte completo de monitoreo."""
        report = {
            "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "agent": self.name,
            "version": self.version,
            "watched_paths": self.watch_paths,
            "folders": []
        }
        
        for path in self.watch_paths:
            folder_report = {
                "path": path,
                "recent": self.scan_folder(path, 10),
                "large": self.detect_large_files(path, 50),
                "organization": self.suggest_organization(path)
            }
            report["folders"].append(folder_report)
        
        return report
    
    def format_report_text(self, report):
        """Formatea reporte como texto legible."""
        lines = [
            f"👁️ REPORTE DE MONITOREO — {report['date']}",
            f"   Agente: {report['agent']} v{report['version']}",
            "=" * 50,
            ""
        ]
        
        for folder in report["folders"]:
            path = folder["path"]
            lines.append(f"📁 {path}")
            
            recent = folder["recent"]
            if "error" not in recent:
                lines.append(f"   Archivos recientes: {recent['count']}")
                for f in recent.get("files", [])[:5]:
                    lines.append(f"   • {f['name'][:40]} ({f['size_human']})")
            else:
                lines.append(f"   ⚠️ {recent['error']}")
            
            large = folder["large"]
            if "error" not in large and large.get("files"):
                lines.append(f"   ⚠️ Archivos grandes: {large['count']}")
                for f in large["files"]:
                    lines.append(f"   • {f['name'][:30]} ({f['size_mb']} MB)")
            
            org = folder["organization"]
            if "error" not in org and org.get("suggestions"):
                lines.append(f"   💡 Sugerencias:")
                for s in org["suggestions"]:
                    lines.append(f"   • {s['action']}")
            
            lines.append("")
        
        return "\n".join(lines)
    
    def _human_size(self, size):
        """Convierte bytes a formato humano."""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024:
                return f"{size:.1f} {unit}"
            size /= 1024
        return f"{size:.1f} PB"
    
    def info(self):
        return {"name": self.name, "version": self.version, "methods": [
            "scan_folder", "detect_large_files", "suggest_organization",
            "full_report", "format_report_text"
        ]}
