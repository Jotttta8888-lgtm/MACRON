"""
MACRON Focus v1.0
Modo Focus - Silenciar notificaciones durante tareas
"""
import os
import time

FOCUS_FILE = os.path.expanduser("~/Documents/MACRON/.focus_mode")

def is_focus_mode():
    return os.path.exists(FOCUS_FILE)

def enable_focus(duration_minutes=25):
    with open(FOCUS_FILE, 'w') as f:
        f.write(str(time.time() + duration_minutes * 60))
    return True

def disable_focus():
    if os.path.exists(FOCUS_FILE):
        os.remove(FOCUS_FILE)
    return True

def get_focus_time_remaining():
    if not is_focus_mode():
        return 0
    with open(FOCUS_FILE, 'r') as f:
        end_time = float(f.read().strip())
    remaining = end_time - time.time()
    return max(0, int(remaining / 60))

def toggle_focus():
    if is_focus_mode():
        disable_focus()
        return "Focus desactivado"
    else:
        enable_focus()
        return "Focus activado (25 min)"

if __name__ == "__main__":
    print(f"Modo Focus: {'Activo' if is_focus_mode() else 'Inactivo'}")
    if is_focus_mode():
        print(f"Tiempo restante: {get_focus_time_remaining()} min")
