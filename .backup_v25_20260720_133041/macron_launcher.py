#!/usr/bin/env python3
"""
MACRON Launcher v4.5
Lanza servidor Flask + UI Tkinter + Menu Bar + Notificaciones
"""
import os
import sys
import subprocess
import time
import signal
import atexit

PROJECT_DIR = os.path.expanduser("~/Documents/MACRON")
VENV_PYTHON = os.path.join(PROJECT_DIR, "venv", "bin", "python3")
SERVER_SCRIPT = os.path.join(PROJECT_DIR, "macron_ui_v3.py")
UI_SCRIPT = os.path.join(PROJECT_DIR, "macron_tkinter.py")
MENUBAR_SCRIPT = os.path.join(PROJECT_DIR, "macron_menubar.py")

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

def start_menubar():
    env = os.environ.copy()
    env["PYTHONPATH"] = PROJECT_DIR
    p = subprocess.Popen(
        [VENV_PYTHON, MENUBAR_SCRIPT],
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
    # Importar notificaciones
    sys.path.insert(0, PROJECT_DIR)
    from macron_notifications import MacronNotifications
    notifier = MacronNotifications()
    
    print("=" * 50)
    print("  MACRON v4.5 - Launcher")
    print("  Iniciando servidor + UI + Menu Bar + Notificaciones...")
    print("=" * 50)
    
    atexit.register(cleanup)
    signal.signal(signal.SIGTERM, lambda s, f: cleanup())
    
    print("[1/4] Iniciando servidor Flask...")
    server_proc = start_server()
    
    print("[2/4] Esperando servidor...")
    if wait_for_server():
        print("[2/4] Servidor listo!")
        notifier.server_started()
    else:
        print("[2/4] Timeout esperando servidor, continuando...")
        notifier.error("Timeout esperando servidor")
    
    print("[3/4] Iniciando Menu Bar...")
    menubar_proc = start_menubar()
    
    print("[4/4] Iniciando interfaz...")
    ui_proc = start_ui()
    
    notifier.welcome()
    
    print("\n✅ MACRON ejecutandose!")
    print("   Servidor: http://127.0.0.1:5004")
    print("   UI: Ventana Tkinter")
    print("   Menu Bar: Barra superior")
    print("   Notificaciones: Activas")
    print("\nPresiona Ctrl+C para salir\n")
    
    try:
        while True:
            server_alive = server_proc.poll() is None
            ui_alive = ui_proc.poll() is None
            menubar_alive = menubar_proc.poll() is None
            if not server_alive and not ui_alive and not menubar_alive:
                break
            if not server_alive:
                print("[WARN] Servidor caido, reiniciando...")
                notifier.error("Servidor caido, reiniciando...")
                server_proc = start_server()
            if not ui_alive:
                print("[WARN] UI cerrada, saliendo...")
                notifier.server_stopped()
                break
            if not menubar_alive:
                print("[WARN] Menu Bar caido, reiniciando...")
                menubar_proc = start_menubar()
            time.sleep(2)
    except KeyboardInterrupt:
        print("\n[Cerrando MACRON...]")
        notifier.server_stopped()
    finally:
        cleanup()

if __name__ == "__main__":
    main()
