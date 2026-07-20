"""
macron/adapters/notes.py
NotesAdapter para MACRON v3.0 - Hereda de BaseAdapter
"""
from .base import BaseAdapter

class NotesAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "notes"
    __version__ = "3.0"
    __dependencies__ = []
    __app_name__ = "Notes"
    
    def __init__(self, core=None):
        super().__init__(core)
    
    def _action_to_applescript(self, action, **kwargs):
        """Mapea acciones a scripts AppleScript."""
        if action == "get_accounts":
            return 'tell application "Notes" to return name of accounts'
        
        elif action == "get_folders":
            return 'tell application "Notes" to return name of folders'
        
        elif action == "get_notes":
            return 'tell application "Notes" to return name of notes'
        
        elif action == "search_notes":
            query = kwargs.get("query", "")
            return (
                'tell application "Notes"\n'
                '    set foundNotes to {}\n'
                '    repeat with n in notes\n'
                '        if "' + query + '" is in name of n or "' + query + '" is in body of n then\n'
                '            set end of foundNotes to (name of n)\n'
                '        end if\n'
                '    end repeat\n'
                '    return foundNotes\n'
                'end tell'
            )
        
        elif action == "get_note_content":
            title = kwargs.get("title", "")
            return (
                'tell application "Notes"\n'
                '    repeat with n in notes\n'
                '        if name of n is "' + title + '" then\n'
                '            return body of n\n'
                '        end if\n'
                '    end repeat\n'
                '    return "Nota no encontrada"\n'
                'end tell'
            )
        
        elif action == "create_note":
            title = kwargs.get("title", "")
            body = kwargs.get("body", "")
            folder = kwargs.get("folder", "Notes")
            return (
                'tell application "Notes"\n'
                '    tell folder "' + folder + '"\n'
                '        set newNote to make new note with properties {name:"' + title + '", body:"' + body + '"}\n'
                '        return "Nota creada: " & name of newNote\n'
                '    end tell\n'
                'end tell'
            )
        else:
            raise NotImplementedError(f"Accion '{action}' no implementada en NotesAdapter")
    
    def get_accounts(self):
        """Lista cuentas de Notes."""
        result = self._run(self._script("get_accounts"), timeout=15)
        if not result.success:
            return []
        return [a.strip() for a in result.stdout.split(",") if a.strip()]
    
    def get_folders(self):
        """Lista carpetas de Notes."""
        result = self._run(self._script("get_folders"), timeout=15)
        if not result.success:
            return []
        return [f.strip() for f in result.stdout.split(",") if f.strip()]
    
    def get_notes(self, limit=20):
        """Obtiene notas recientes."""
        result = self._run(self._script("get_notes"), timeout=15)
        if not result.success:
            return []
        notes = []
        for line in result.stdout.split(","):
            line = line.strip()
            if line:
                notes.append({"title": line, "modified": ""})
        return notes[:limit]
    
    def search_notes(self, query, limit=10):
        """Busca notas por titulo o contenido."""
        result = self._run(self._script("search_notes", query=query), timeout=15)
        if not result.success:
            return []
        notes = []
        for line in result.stdout.split(","):
            line = line.strip()
            if line:
                notes.append({"title": line, "modified": ""})
        return notes[:limit]
    
    def get_note_content(self, title):
        """Obtiene contenido de una nota."""
        result = self._run(self._script("get_note_content", title=title), timeout=15)
        if not result.success:
            return {"error": result.stderr}
        return {"title": title, "content": result.stdout}
    
    def create_note(self, title, body, folder="Notes"):
        """Crea nueva nota."""
        result = self._run(self._script("create_note", title=title, body=body, folder=folder), timeout=15)
        if not result.success:
            return {"success": False, "error": result.stderr}
        return {"success": True, "message": result.stdout}
    
    def info(self):
        return {"name": self.name, "version": self.version, "app": "Notes", "methods": [
            "get_accounts", "get_folders", "get_notes", "search_notes",
            "get_note_content", "create_note"
        ]}
