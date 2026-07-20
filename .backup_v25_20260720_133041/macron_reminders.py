"""
macron_reminders.py
Integracion con Recordatorios para MACRON v7.7
Funcionalidades: listar, crear, completar, buscar recordatorios
"""
import subprocess

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

def get_lists():
    """Lista las listas de recordatorios."""
    script = 'tell application "Reminders" to return name of lists'
    result = _run_applescript(script)
    if "error" in result:
        return []
    return [l.strip() for l in result.get("output", "").split(",") if l.strip()]

def get_reminders(list_name="Recordatorios", completed=False, limit=20):
    """Obtiene recordatorios de una lista."""
    script = f'''tell application "Reminders"
        set remList to {{}}
        repeat with r in (reminders of list "{list_name}" whose completed is {str(completed).lower()})
            set end of remList to (name of r & "|" & due date of r as string & "|" & priority of r as string)
        end repeat
        return remList
    end tell'''
    result = _run_applescript(script)
    if "error" in result:
        return []
    reminders = []
    for line in result.get("output", "").split("\n"):
        if "|" in line:
            parts = line.split("|")
            reminders.append({
                "title": parts[0],
                "due": parts[1] if len(parts) > 1 else "",
                "priority": parts[2] if len(parts) > 2 else "0"
            })
    return reminders[:limit]

def create_reminder(title, list_name="Recordatorios", due_date=None, notes="", priority=0):
    """Crea un nuevo recordatorio."""
    due_str = f', due date:date "{due_date}"' if due_date else ""
    script = f'''tell application "Reminders"
        tell list "{list_name}"
            set newRem to make new reminder with properties {{name:"{title}"{due_str}, body:"{notes}", priority:{priority}}}
            return "Creado: " & name of newRem
        end tell
    end tell'''
    result = _run_applescript(script)
    if "error" in result:
        return {"success": False, "error": result["error"]}
    return {"success": True, "message": result.get("output", "Creado")}

def complete_reminder(title, list_name="Recordatorios"):
    """Marca un recordatorio como completado."""
    script = f'''tell application "Reminders"
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
    result = _run_applescript(script)
    if "error" in result:
        return {"success": False, "error": result["error"]}
    return {"success": True, "message": result.get("output", "Completado")}

# -- CLI TEST --
if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Reminders Integration v7.7")
    print("=" * 50)
    
    print("\n📋 LISTAS:")
    for l in get_lists():
        print(f"   • {l}")
    
    print("\n⏰ PENDIENTES:")
    rems = get_reminders("Recordatorios", False, 10)
    if rems:
        for r in rems:
            print(f"   • {r['title']}")
            if r['due']: print(f"     Vence: {r['due']}")
    else:
        print("   No hay recordatorios pendientes.")
    
    print("\n" + "=" * 50)
    print("Reminders Integration listo")
    print("=" * 50)
