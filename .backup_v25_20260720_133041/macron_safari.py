"""
macron_safari.py
Integracion con Safari para MACRON v6.6.2
"""
import os
import subprocess
import json
from datetime import datetime
from urllib.parse import urlparse

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

def get_tabs():
    """Lista todas las pestanas abiertas en Safari."""
    script = """
    tell application "Safari"
        set output to ""
        repeat with wIndex from 1 to count of windows
            set w to window wIndex
            repeat with tIndex from 1 to count of tabs of w
                set t to tab tIndex of w
                set output to output & (name of t) & "|" & (URL of t) & "|" & wIndex & "\n"
            end repeat
        end repeat
        return output
    end tell
    """
    result = _run_applescript(script)
    if "error" in result:
        return []
    tabs = []
    for line in result.get("output", "").strip().split("\n"):
        if "|" in line:
            parts = line.split("|")
            if len(parts) >= 3:
                tabs.append({
                    "title": parts[0],
                    "url": parts[1],
                    "window_index": int(parts[2]) if parts[2].isdigit() else 1
                })
    return tabs

def get_active_tab():
    """Devuelve la pestana activa actual."""
    script = """
    tell application "Safari"
        set t to current tab of front window
        return (name of t) & "|" & (URL of t)
    end tell
    """
    result = _run_applescript(script)
    if "error" in result:
        return None
    parts = result.get("output", "").split("|")
    if len(parts) >= 2:
        return {"title": parts[0], "url": parts[1]}
    return None

def get_page_content():
    """Extrae el texto visible de la pagina activa."""
    script = """
    tell application "Safari"
        set pageText to do JavaScript "document.body.innerText" in current tab of front window
        return pageText
    end tell
    """
    result = _run_applescript(script)
    if "error" in result:
        return ""
    text = result.get("output", "")
    lines = [line.strip() for line in text.split("\n") if line.strip()]
    return "\n".join(lines[:500])

def summarize_page(core=None):
    """Resume el contenido de la pagina activa usando el LLM."""
    content = get_page_content()
    if not content:
        return {"error": "No se pudo obtener contenido", "summary": ""}
    max_chars = 4000
    if len(content) > max_chars:
        content = content[:max_chars] + "...\n[Contenido truncado]"
    prompt = f"""Resume el siguiente articulo en 3-5 puntos clave. Se conciso:

{content}

Resumen:"""
    if core and hasattr(core, 'chat'):
        try:
            result = core.chat(prompt)
            if isinstance(result, dict):
                summary = result.get('text', '') or result.get('response', '') or str(result)
            else:
                summary = str(result)
            active = get_active_tab() or {}
            return {"summary": summary, "url": active.get('url', ''), "title": active.get('title', '')}
        except Exception as e:
            return {"error": str(e), "summary": ""}
    lines = content.split("\n")[:10]
    return {"summary": "Resumen automatico:\n" + "\n".join(f"- {line[:100]}" for line in lines if len(line) > 20), "url": "", "title": ""}

def search_in_page(query):
    """Busca texto en la pagina activa."""
    content = get_page_content().lower()
    query_lower = query.lower()
    if query_lower in content:
        idx = content.find(query_lower)
        start = max(0, idx - 100)
        end = min(len(content), idx + 200)
        return {"found": True, "context": content[start:end], "occurrences": content.count(query_lower)}
    return {"found": False, "context": "", "occurrences": 0}

def save_for_later(title=None, url=None, notes=""):
    """Guarda URL para leer despues."""
    save_file = os.path.expanduser("~/Documents/MACRON/safari_read_later.json")
    if url is None:
        tab = get_active_tab()
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
    if os.path.exists(save_file):
        try:
            with open(save_file, "r", encoding="utf-8") as f:
                data = json.load(f)
        except:
            data = []
    for item in data:
        if item.get("url") == url:
            return {"success": False, "error": "URL ya guardada", "entry": entry}
    data.append(entry)
    try:
        with open(save_file, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        return {"success": True, "entry": entry, "total_saved": len(data)}
    except Exception as e:
        return {"success": False, "error": str(e)}

def get_read_later_list():
    """Devuelve lista de URLs guardadas."""
    save_file = os.path.expanduser("~/Documents/MACRON/safari_read_later.json")
    if not os.path.exists(save_file):
        return []
    try:
        with open(save_file, "r", encoding="utf-8") as f:
            return json.load(f)
    except:
        return []

def open_url(url, in_new_tab=True):
    """Abre URL en Safari."""
    if in_new_tab:
        script = f'tell application "Safari"\nmake new document\nset URL of current tab of front window to "{url}"\nactivate\nend tell'
    else:
        script = f'tell application "Safari"\nset URL of current tab of front window to "{url}"\nactivate\nend tell'
    return _run_applescript(script)

def close_tab(tab_index=None, window_index=1):
    """Cierra pestana especifica o la activa."""
    if tab_index is None:
        script = 'tell application "Safari"\nclose current tab of front window\nend tell'
    else:
        script = f'tell application "Safari"\nclose tab {tab_index} of window {window_index}\nend tell'
    return _run_applescript(script)

def get_domain_summary():
    """Devuelve resumen de dominios abiertos."""
    tabs = get_tabs()
    domains = {}
    for tab in tabs:
        domain = urlparse(tab.get("url", "")).netloc
        if domain:
            domains[domain] = domains.get(domain, 0) + 1
    return sorted(domains.items(), key=lambda x: x[1], reverse=True)

if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Safari Integration v7.1")
    print("=" * 50)
    print("\n📑 PESTANAS ABIERTAS:")
    tabs = get_tabs()
    print(f"   Total: {len(tabs)} pestanas")
    for i, t in enumerate(tabs[:5], 1):
        print(f"   {i}. {t.get('title', 'Sin titulo')[:50]}")
    if len(tabs) > 5:
        print(f"   ... y {len(tabs) - 5} mas")
    print("\n🌐 PESTANA ACTIVA:")
    active = get_active_tab()
    if active:
        print(f"   Titulo: {active.get('title', 'N/A')[:60]}")
        print(f"   URL: {active.get('url', 'N/A')[:70]}")
    print("\n📊 DOMINIOS:")
    for domain, count in get_domain_summary()[:5]:
        print(f"   {domain}: {count} pestana(s)")
    print("\n" + "=" * 50)
    print("Safari Integration listo")
    print("=" * 50)
