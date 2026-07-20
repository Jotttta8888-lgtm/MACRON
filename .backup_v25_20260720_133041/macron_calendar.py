"""
macron_calendar.py
Integracion con Calendario para MACRON v7.4
Funcionalidades: listar eventos, crear eventos, proximos eventos, buscar
"""
import subprocess
import json
from datetime import datetime, timedelta

def _run_applescript(script):
    """Ejecuta AppleScript y devuelve resultado."""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0:
            return {"error": result.stderr.strip()}
        return {"success": True, "output": result.stdout.strip()}
    except Exception as e:
        return {"error": str(e)}

def get_calendars():
    """Lista los calendarios disponibles."""
    script = 'tell application "Calendar" to return name of calendars'
    result = _run_applescript(script)
    if "error" in result:
        return []
    return [c.strip() for c in result.get("output", "").split(",") if c.strip()]

def get_today_events():
    """Obtiene eventos de hoy."""
    script = '''tell application "Calendar"
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
    result = _run_applescript(script)
    if "error" in result:
        return []
    events = []
    for line in result.get("output", "").split("\n"):
        if "|" in line:
            parts = line.split("|")
            events.append({
                "title": parts[0],
                "start": parts[1] if len(parts) > 1 else "",
                "location": parts[2] if len(parts) > 2 else "",
                "description": parts[3] if len(parts) > 3 else ""
            })
    return events

def get_upcoming_events(days=7, limit=10):
    """Obtiene proximos eventos en N dias."""
    script = f'''tell application "Calendar"
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
    result = _run_applescript(script)
    if "error" in result:
        return []
    events = []
    for line in result.get("output", "").split("\n"):
        if "|" in line:
            parts = line.split("|")
            events.append({
                "title": parts[0],
                "start": parts[1] if len(parts) > 1 else "",
                "end": parts[2] if len(parts) > 2 else "",
                "location": parts[3] if len(parts) > 3 else ""
            })
    return events[:limit]

def create_event(title, start_date, duration_hours=1, calendar_name=None, location="", notes=""):
    """Crea un nuevo evento en el calendario."""
    cal = calendar_name if calendar_name else "Calendario"
    script = f'''tell application "Calendar"
        tell calendar "{cal}"
            set newEvent to make new event with properties {{summary:"{title}", start date:date "{start_date}", end date:date "{start_date}" + {duration_hours} * hours'''
    if location:
        script += f', location:"{location}"'
    if notes:
        script += f', description:"{notes}"'
    script += '''}
            return "Evento creado: " & summary of newEvent & " el " & start date of newEvent as string
        end tell
    end tell'''
    result = _run_applescript(script)
    if "error" in result:
        return {"success": False, "error": result["error"]}
    return {"success": True, "message": result.get("output", "Creado")}

def search_events(query, days=30):
    """Busca eventos por titulo."""
    script = f'''tell application "Calendar"
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
    result = _run_applescript(script)
    if "error" in result:
        return []
    events = []
    for line in result.get("output", "").split("\n"):
        if "|" in line:
            parts = line.split("|")
            events.append({"title": parts[0], "start": parts[1]})
    return events

# ── CLI TEST ────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Calendar Integration v7.4")
    print("=" * 50)
    
    print("\n📅 CALENDARIOS:")
    for c in get_calendars():
        print(f"   • {c}")
    
    print("\n📆 EVENTOS DE HOY:")
    events = get_today_events()
    if events:
        for e in events[:5]:
            print(f"   • {e['title']}")
            print(f"     {e['start']}")
    else:
        print("   No hay eventos hoy.")
    
    print("\n🔜 PROXIMOS 7 DIAS:")
    upcoming = get_upcoming_events(7, 5)
    if upcoming:
        for e in upcoming:
            print(f"   • {e['title']}")
            print(f"     Inicio: {e['start']}")
    else:
        print("   No hay eventos proximos.")
    
    print("\n" + "=" * 50)
    print("Calendar Integration listo")
    print("=" * 50)
