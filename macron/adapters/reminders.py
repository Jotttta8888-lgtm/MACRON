"""
macron/adapters/reminders.py
RemindersAdapter para MACRON v3.0 - Hereda de BaseAdapter
"""
from .base import BaseAdapter

class RemindersAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "reminders"
    __version__ = "3.0"
    __dependencies__ = []
    __app_name__ = "Reminders"
    
    def __init__(self, core=None):
        super().__init__(core)
    
    def _action_to_applescript(self, action, **kwargs):
        """Mapea acciones a scripts AppleScript."""
        if action == "get_lists":
            return 'tell application "Reminders" to return name of lists'
        
        elif action == "get_reminders":
            list_name = kwargs.get("list_name", "Recordatorios")
            completed = kwargs.get("completed", False)
            return f'''tell application "Reminders"
    set remList to {{}}
    repeat with r in (reminders of list "{list_name}" whose completed is {str(completed).lower()})
        set end of remList to (name of r & "|" & due date of r as string & "|" & priority of r as string)
    end repeat
    return remList
end tell'''
        
        elif action == "create_reminder":
            title = kwargs.get("title", "")
            list_name = kwargs.get("list_name", "Recordatorios")
            due_date = kwargs.get("due_date")
            notes = kwargs.get("notes", "")
            priority = kwargs.get("priority", 0)
            due_str = f', due date:date "{due_date}"' if due_date else ""
            return f'''tell application "Reminders"
    tell list "{list_name}"
        set newRem to make new reminder with properties {{name:"{title}"{due_str}, body:"{notes}", priority:{priority}}}
        return "Creado: " & name of newRem
    end tell
end tell'''
        
        elif action == "complete_reminder":
            title = kwargs.get("title", "")
            list_name = kwargs.get("list_name", "Recordatorios")
            return f'''tell application "Reminders"
    tell list "{list_name}"
        repeat with r in reminders
            if name of r is "{title}" then
                set completed of r to true
                return "Completado: " & name of r
            end if
        end repeat
        return "No encontrado"
    end tell
end tell'''
        else:
            raise NotImplementedError(f"Accion '{action}' no implementada en RemindersAdapter")
    
    def get_lists(self):
        """Lista listas de recordatorios."""
        result = self._run(self._script("get_lists"), timeout=15)
        if not result.success:
            return []
        return [l.strip() for l in result.stdout.split(",") if l.strip()]
    
    def get_reminders(self, list_name="Recordatorios", completed=False, limit=20):
        """Obtiene recordatorios de una lista."""
        result = self._run(self._script("get_reminders", list_name=list_name, completed=completed), timeout=15)
        if not result.success:
            return []
        reminders = []
        for line in result.stdout.split("\n"):
            if "|" in line:
                parts = line.split("|")
                reminders.append({
                    "title": parts[0],
                    "due": parts[1] if len(parts) > 1 else "",
                    "priority": parts[2] if len(parts) > 2 else "0"
                })
        return reminders[:limit]
    
    def create_reminder(self, title, list_name="Recordatorios", due_date=None, notes="", priority=0):
        """Crea nuevo recordatorio."""
        result = self._run(self._script("create_reminder", title=title, list_name=list_name, 
            due_date=due_date, notes=notes, priority=priority), timeout=15)
        if not result.success:
            return {"success": False, "error": result.stderr}
        return {"success": True, "message": result.stdout}
    
    def complete_reminder(self, title, list_name="Recordatorios"):
        """Marca recordatorio como completado."""
        result = self._run(self._script("complete_reminder", title=title, list_name=list_name), timeout=15)
        if not result.success:
            return {"success": False, "error": result.stderr}
        return {"success": True, "message": result.stdout}
    
    def info(self):
        return {"name": self.name, "version": self.version, "app": "Reminders", "methods": [
            "get_lists", "get_reminders", "create_reminder", "complete_reminder"
        ]}
