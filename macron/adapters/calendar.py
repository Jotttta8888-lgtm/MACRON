"""
macron/adapters/calendar.py
CalendarAdapter para MACRON v3.0 - Hereda de BaseAdapter
"""
from .base import BaseAdapter

class CalendarAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "calendar"
    __version__ = "3.0"
    __dependencies__ = []
    __app_name__ = "Calendar"
    
    def __init__(self, core=None):
        super().__init__(core)
    
    def _action_to_applescript(self, action, **kwargs):
        """Mapea acciones a scripts AppleScript."""
        if action == "get_calendars":
            return 'tell application "Calendar" to return name of calendars'
        
        elif action == "get_today_events":
            return '''tell application "Calendar"
    set todayStart to (current date)
    set time of todayStart to 0
    set todayEnd to todayStart + 1 * days
    set allEvents to {}
    repeat with c in calendars
        repeat with e in (events of c whose start date >= todayStart and start date < todayEnd)
            set end of allEvents to (summary of e & "|" & start date of e as string & "|" & (location of e as string) & "|" & (description of e as string))
        end repeat
    end repeat
    return allEvents
end tell'''
        
        elif action == "get_upcoming_events":
            days = kwargs.get("days", 7)
            return f'''tell application "Calendar"
    set now to (current date)
    set future to now + {days} * days
    set allEvents to {{}}
    repeat with c in calendars
        repeat with e in (events of c whose start date >= now and start date <= future)
            set end of allEvents to (summary of e & "|" & start date of e as string & "|" & end date of e as string & "|" & (location of e as string))
        end repeat
    end repeat
    return allEvents
end tell'''
        
        elif action == "create_event":
            title = kwargs.get("title", "")
            start_date = kwargs.get("start_date", "")
            duration_hours = kwargs.get("duration_hours", 1)
            calendar_name = kwargs.get("calendar_name", "Calendario")
            location = kwargs.get("location", "")
            notes = kwargs.get("notes", "")
            script = f'''tell application "Calendar"
    tell calendar "{calendar_name}"
        set newEvent to make new event with properties {{summary:"{title}", start date:date "{start_date}", end date:date "{start_date}" + {duration_hours} * hours'''
            if location:
                script += f', location:"{location}"'
            if notes:
                script += f', description:"{notes}"'
            script += '''}
        return "Evento creado: " & summary of newEvent & " el " & start date of newEvent as string
    end tell
end tell'''
            return script
        
        elif action == "search_events":
            query = kwargs.get("query", "")
            days = kwargs.get("days", 30)
            return f'''tell application "Calendar"
    set now to (current date)
    set future to now + {days} * days
    set allEvents to {{}}
    repeat with c in calendars
        repeat with e in (events of c whose start date >= now and start date <= future)
            if "{query}" is in summary of e then
                set end of allEvents to (summary of e & "|" & start date of e as string)
            end if
        end repeat
    end repeat
    return allEvents
end tell'''
        else:
            raise NotImplementedError(f"Accion '{action}' no implementada en CalendarAdapter")
    
    def get_calendars(self):
        """Lista calendarios disponibles."""
        result = self._run(self._script("get_calendars"), timeout=15)
        if not result.success:
            return []
        return [c.strip() for c in result.stdout.split(",") if c.strip()]
    
    def get_today_events(self):
        """Obtiene eventos de hoy."""
        result = self._run(self._script("get_today_events"), timeout=15)
        if not result.success:
            return []
        events = []
        for line in result.stdout.split("\n"):
            if "|" in line:
                parts = line.split("|")
                events.append({
                    "title": parts[0],
                    "start": parts[1] if len(parts) > 1 else "",
                    "location": parts[2] if len(parts) > 2 else "",
                    "description": parts[3] if len(parts) > 3 else ""
                })
        return events
    
    def get_upcoming_events(self, days=7, limit=10):
        """Obtiene proximos eventos en N dias."""
        result = self._run(self._script("get_upcoming_events", days=days), timeout=15)
        if not result.success:
            return []
        events = []
        for line in result.stdout.split("\n"):
            if "|" in line:
                parts = line.split("|")
                events.append({
                    "title": parts[0],
                    "start": parts[1] if len(parts) > 1 else "",
                    "end": parts[2] if len(parts) > 2 else "",
                    "location": parts[3] if len(parts) > 3 else ""
                })
        return events[:limit]
    
    def create_event(self, title, start_date, duration_hours=1, calendar_name=None, location="", notes=""):
        """Crea nuevo evento."""
        cal = calendar_name if calendar_name else "Calendario"
        result = self._run(self._script("create_event", title=title, start_date=start_date, 
            duration_hours=duration_hours, calendar_name=cal, location=location, notes=notes), timeout=15)
        if not result.success:
            return {"success": False, "error": result.stderr}
        return {"success": True, "message": result.stdout}
    
    def search_events(self, query, days=30):
        """Busca eventos por titulo."""
        result = self._run(self._script("search_events", query=query, days=days), timeout=15)
        if not result.success:
            return []
        events = []
        for line in result.stdout.split("\n"):
            if "|" in line:
                parts = line.split("|")
                events.append({"title": parts[0], "start": parts[1]})
        return events
    
    def info(self):
        return {"name": self.name, "version": self.version, "app": "Calendar", "methods": [
            "get_calendars", "get_today_events", "get_upcoming_events",
            "create_event", "search_events"
        ]}
