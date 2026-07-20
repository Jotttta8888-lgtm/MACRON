content = """#!/usr/bin/env python3
import os
import subprocess
import time
import signal
import atexit

PROJECT_DIR = os.path.expanduser("~/Documents/MACRON")
VENV_PYTHON = os.path.join(PROJECT_DIR, "venv", "bin", "python3")
SERVER_SCRIPT = os.path.join(PROJECT_DIR, "macron_ui_v3.py")
UI_SCRIPT = os.path.join(PROJECT_DIR, "macron_tkinter.py")

processes = []

def cleanup():
    for p in processes:
        try:
            p.terminate()
            p.wait(timeout=5)
        except:
            try:
                p.kill()
            except:
                pass

def start_server():
    env = os.environ.copy()
    env["PYTHONPATH"] = PROJECT_DIR
    p = subprocess.Popen(
        [VENV_PYTHON, SERVER_SCRIPT],
        cwd=PROJECT_DIR,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True
    )
    processes.append(p)
    return p

def start_ui():
    env = os.environ.copy()
    env["PYTHONPATH"] = PROJECT_DIR
    p = subprocess.Popen(
        [VENV_PYTHON, UI_SCRIPT],
        cwd=PROJECT_DIR,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True
    )
    processes.append(p)
    return p

def wait_for_server(timeout=120):
    import urllib.request
    start = time.time()
    while time.time() - start < timeout:
        try:
            req = urllib.request.Request("http://127.0.0.1:5004/api/status")
            with urllib.request.urlopen(req, timeout=2) as resp:
                if resp.status == 200:
                    return True
        except:
            time.sleep(1)
    return False

def main():
    print("=" * 50)
    print("  MACRON v4.2 - Launcher")
    print("  Iniciando servidor + UI...")
    print("=" * 50)
    
    atexit.register(cleanup)
    signal.signal(signal.SIGTERM, lambda s, f: cleanup())
    
    print("[1/3] Iniciando servidor Flask...")
    server_proc = start_server()
    
    print("[2/3] Esperando servidor...")
    if wait_for_server():
        print("[2/3] Servidor listo!")
    else:
        print("[2/3] Timeout esperando servidor, continuando...")
    
    print("[3/3] Iniciando interfaz...")
    ui_proc = start_ui()
    
    print("\\n✅ MACRON ejecutandose!")
    print("   Servidor: http://127.0.0.1:5004")
    print("   UI: Ventana Tkinter")
    print("\\nPresiona Ctrl+C para salir\\n")
    
    try:
        while True:
            server_alive = server_proc.poll() is None
            ui_alive = ui_proc.poll() is None
            if not server_alive and not ui_alive:
                break
            if not server_alive:
                print("[WARN] Servidor caido, reiniciando...")
                server_proc = start_server()
            if not ui_alive:
                print("[WARN] UI cerrada, saliendo...")
                break
            time.sleep(2)
    except KeyboardInterrupt:
        print("\\n[Cerrando MACRON...]")
    finally:
        cleanup()

if __name__ == "__main__":
    main()
"""

with open('macron_launcher.py', 'w') as f:
    f.write(content)
print("OK")
