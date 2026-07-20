"""
MACRON Hotkey v1.0
Atajo de teclado global: Cmd+Shift+M para abrir MACRON
"""
import subprocess
import os
from pynput import keyboard

class MacronHotkey:
    def __init__(self):
        self.combination = {keyboard.Key.cmd, keyboard.Key.shift, keyboard.KeyCode.from_char('m')}
        self.current_keys = set()
        self.listener = None
    
    def on_press(self, key):
        """Detecta cuando se presiona una tecla"""
        if key in self.combination:
            self.current_keys.add(key)
            if self.current_keys == self.combination:
                self.open_macron()
    
    def on_release(self, key):
        """Detecta cuando se suelta una tecla"""
        try:
            self.current_keys.remove(key)
        except KeyError:
            pass
    
    def open_macron(self):
        """Abre MACRON"""
        print("[Hotkey] Cmd+Shift+M detectado - Abriendo MACRON...")
        try:
            subprocess.Popen(["open", "/Applications/MACRON.app"])
        except Exception as e:
            print(f"[Hotkey] Error: {e}")
    
    def start(self):
        """Inicia el listener de teclado"""
        print("[Hotkey] Atajo Cmd+Shift+M activo")
        print("[Hotkey] Presiona Cmd+Shift+M para abrir MACRON")
        self.listener = keyboard.Listener(on_press=self.on_press, on_release=self.on_release)
        self.listener.start()
        return self.listener
    
    def stop(self):
        """Detiene el listener"""
        if self.listener:
            self.listener.stop()

if __name__ == "__main__":
    import time
    hotkey = MacronHotkey()
    listener = hotkey.start()
    
    try:
        while listener.is_alive():
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[Hotkey] Deteniendo...")
        hotkey.stop()
