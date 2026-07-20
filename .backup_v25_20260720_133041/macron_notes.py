"""
macron_notes.py
Integracion con Apple Notes para MACRON v7.5
Funcionalidades: listar notas, buscar, crear, leer contenido
"""
import subprocess
import json

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

def get_accounts():
    """Lista las cuentas de Notes."""
    script = 'tell application "Notes" to return name of accounts'
    result = _run_applescript(script)
    if "error" in result:
        return []
    return [a.strip() for a in result.get("output", "").split(",") if a.strip()]

def get_folders():
    """Lista las carpetas de Notes."""
    script = 'tell application "Notes" to return name of folders'
    result = _run_applescript(script)
    if "error" in result:
        return []
    return [f.strip() for f in result.get("output", "").split(",") if f.strip()]

def get_notes(limit=20):
    """Obtiene las notas recientes."""
    script = 'tell application "Notes" to return name of notes'
    result = _run_applescript(script)
    if "error" in result:
        return []
    notes = []
    for line in result.get("output", "").split(","):
        line = line.strip()
        if line:
            notes.append({"title": line, "modified": ""})
    return notes[:limit]

def search_notes(query, limit=10):
    """Busca notas por titulo o contenido."""
    script = (
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
    result = _run_applescript(script)
    if "error" in result:
        return []
    notes = []
    for line in result.get("output", "").split(","):
        line = line.strip()
        if line:
            notes.append({"title": line, "modified": ""})
    return notes[:limit]

def get_note_content(title):
    """Obtiene el contenido de una nota por titulo."""
    script = (
        'tell application "Notes"\n'
        '    repeat with n in notes\n'
        '        if name of n is "' + title + '" then\n'
        '            return body of n\n'
        '        end if\n'
        '    end repeat\n'
        '    return "Nota no encontrada"\n'
        'end tell'
    )
    result = _run_applescript(script)
    if "error" in result:
        return {"error": result["error"]}
    return {"title": title, "content": result.get("output", "")}

def create_note(title, body, folder="Notes"):
    """Crea una nueva nota."""
    script = (
        'tell application "Notes"\n'
        '    tell folder "' + folder + '"\n'
        '        set newNote to make new note with properties {name:"' + title + '", body:"' + body + '"}\n'
        '        return "Nota creada: " & name of newNote\n'
        '    end tell\n'
        'end tell'
    )
    result = _run_applescript(script)
    if "error" in result:
        return {"success": False, "error": result["error"]}
    return {"success": True, "message": result.get("output", "Creada")}

# -- CLI TEST --
if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Notes Integration v7.5")
    print("=" * 50)
    
    print("\n📒 CUENTAS:")
    for a in get_accounts():
        print(f"   • {a}")
    
    print("\n📁 CARPETAS:")
    for f in get_folders():
        print(f"   • {f}")
    
    print("\n📝 NOTAS RECIENTES (10):")
    notes = get_notes(10)
    if notes:
        for n in notes:
            print(f"   • {n['title'][:50]}...")
    else:
        print("   No hay notas recientes.")
    
    print("\n" + "=" * 50)
    print("Notes Integration listo")
    print("=" * 50)