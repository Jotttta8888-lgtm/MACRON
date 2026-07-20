"""
macron/adapters/safari.py
SafariAdapter para MACRON v3.0
"""
import os
import json
from datetime import datetime
from urllib.parse import urlparse
from .base import BaseAdapter

class SafariAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "safari"
    __version__ = "3.0"
    __dependencies__ = []
    __app_name__ = "Safari"
    
    def __init__(self, core=None):
        super().__init__(core)
        self._read_later_file = os.path.expanduser("~/Documents/MACRON/safari_read_later.json")
    
    def _action_to_applescript(self, action, **kwargs):
        if action == "get_tabs":
            return 'tell application "Safari"\nset output to ""\nrepeat with wIndex from 1 to count of windows\nset w to window wIndex\nrepeat with tIndex from 1 to count of tabs of w\nset t to tab tIndex of w\nset output to output & (name of t) & "|" & (URL of t) & "|" & wIndex & "\\n"\nend repeat\nend repeat\nreturn output\nend tell'
        elif action == "get_active_tab":
            return 'tell application "Safari"\nset t to current tab of front window\nreturn (name of t) & "|" & (URL of t)\nend tell'
        elif action == "get_page_content":
            return 'tell application "Safari"\nset pageText to do JavaScript "document.body.innerText" in current tab of front window\nreturn pageText\nend tell'
        elif action == "open_url":
            url = kwargs.get("url", "")
            safe_url = self._escape_applescript(url)
            in_new_tab = kwargs.get("in_new_tab", True)
            if in_new_tab:
                return f'tell application "Safari"\\nmake new document\\nset URL of current tab of front window to "{safe_url}"\\nactivate\\nend tell'
            else:
                return f'tell application "Safari"\\nset URL of current tab of front window to "{safe_url}"\\nactivate\\nend tell'
        elif action == "close_tab":
            tab_index = kwargs.get("tab_index")
            if tab_index is None:
                return 'tell application "Safari"\\nclose current tab of front window\\nend tell'
            else:
                return f'tell application "Safari"\\nclose tab {tab_index} of window 1\\nend tell'
        else:
            raise NotImplementedError(f"Accion '{action}' no implementada")
    
    def get_tabs(self):
        result = self._run(self._script("get_tabs"), timeout=10)
        if not result.success:
            return []
        tabs = []
        for line in result.stdout.strip().split("\n"):
            if "|" in line:
                parts = line.split("|")
                if len(parts) >= 3:
                    tabs.append({"title": parts[0], "url": parts[1], "window_index": int(parts[2]) if parts[2].isdigit() else 1})
        return tabs
    
    def get_active_tab(self):
        result = self._run(self._script("get_active_tab"), timeout=10)
        if not result.success:
            return None
        parts = result.stdout.split("|")
        if len(parts) >= 2:
            return {"title": parts[0], "url": parts[1]}
        return None
    
    def get_page_content(self):
        result = self._run(self._script("get_page_content"), timeout=10)
        if not result.success:
            return ""
        text = result.stdout
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        return "\n".join(lines[:500])
    
    def summarize_page(self):
        content = self.get_page_content()
        if not content:
            return {"error": "No se pudo obtener contenido", "summary": ""}
        max_chars = 4000
        if len(content) > max_chars:
            content = content[:max_chars] + "...\n[Contenido truncado]"
        prompt = f"""Resume el siguiente articulo en 3-5 puntos clave. Se conciso:\n\n{content}\n\nResumen:"""
        if self.core and hasattr(self.core, 'chat'):
            try:
                result = self.core.chat(prompt)
                if isinstance(result, dict):
                    summary = result.get('text', '') or result.get('response', '') or str(result)
                else:
                    summary = str(result)
                active = self.get_active_tab() or {}
                return {"summary": summary, "url": active.get('url', ''), "title": active.get('title', '')}
            except Exception as e:
                return {"error": str(e), "summary": ""}
        lines = content.split("\n")[:10]
        return {"summary": "Resumen automatico:\n" + "\n".join(f"- {line[:100]}" for line in lines if len(line) > 20), "url": "", "title": ""}
    
    def search_in_page(self, query):
        safe_query = self._escape_applescript(query)
        content = self.get_page_content().lower()
        query_lower = safe_query.lower()
        if query_lower in content:
            idx = content.find(query_lower)
            start = max(0, idx - 100)
            end = min(len(content), idx + 200)
            return {"found": True, "context": content[start:end], "occurrences": content.count(query_lower)}
        return {"found": False, "context": "", "occurrences": 0}
    
    def save_for_later(self, title=None, url=None, notes=""):
        if url is None:
            tab = self.get_active_tab()
            if tab:
                url = tab.get("url", "")
                title = title or tab.get("title", "Sin titulo")
        if not url:
            return {"success": False, "error": "No hay URL para guardar"}
        entry = {
            "title": title or "Sin titulo",
            "url": url,
            "notes": notes,
            "saved_at": datetime.now().isoformat(),
            "domain": urlparse(url).netloc
        }
        data = []
        if os.path.exists(self._read_later_file):
            try:
                with open(self._read_later_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except:
                data = []
        for item in data:
            if item.get("url") == url:
                return {"success": False, "error": "URL ya guardada", "entry": entry}
        data.append(entry)
        try:
            with open(self._read_later_file, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            return {"success": True, "entry": entry, "total_saved": len(data)}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_read_later_list(self):
        if not os.path.exists(self._read_later_file):
            return []
        try:
            with open(self._read_later_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            return []
    
    def open_url(self, url, in_new_tab=True):
        result = self._run(self._script("open_url", url=url, in_new_tab=in_new_tab), timeout=10)
        return {"success": result.success, "output": result.stdout, "error": result.stderr}
    
    def close_tab(self, tab_index=None):
        result = self._run(self._script("close_tab", tab_index=tab_index), timeout=10)
        return {"success": result.success, "output": result.stdout, "error": result.stderr}
    
    def get_domain_summary(self):
        tabs = self.get_tabs()
        domains = {}
        for tab in tabs:
            domain = urlparse(tab.get("url", "")).netloc
            if domain:
                domains[domain] = domains.get(domain, 0) + 1
        return sorted(domains.items(), key=lambda x: x[1], reverse=True)
    
    def info(self):
        return {"name": self.name, "version": self.version, "app": "Safari", "methods": [
            "get_tabs", "get_active_tab", "get_page_content", "summarize_page",
            "search_in_page", "save_for_later", "get_read_later_list",
            "open_url", "close_tab", "get_domain_summary"
        ]}
