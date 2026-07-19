#!/usr/bin/env python3
"""
MACRON v3.0 Launcher
Inicia la Web UI con el modulo de voz VAD integrado
"""
import os
import sys
import webbrowser
import threading
import time

MACRON_DIR = os.path.expanduser("~/Documents/MACRON")
os.chdir(MACRON_DIR)
sys.path.insert(0, MACRON_DIR)

def check_dependencies():
    deps = {
        'flask': 'Flask',
        'sounddevice': 'sounddevice', 
        'numpy': 'numpy',
        'mlx_whisper': 'mlx-whisper',
        'mlx': 'mlx'
    }
    missing = []
    for module, package in deps.items():
        try:
            __import__(module)
        except ImportError:
            missing.append(package)
    if missing:
        print("="*50)
        print("  DEPENDENCIAS FALTANTES:")
        for d in missing:
            print(f"    - {d}")
        print("\n  Instalar con:")
        print(f"    pip install {' '.join(missing)}")
        print("="*50)
        return False
    return True

def main():
    print("="*50)
    print("  MACRON v3.0 Launcher")
    print("  Web UI + VAD Voice + Estado Real")
    print("="*50)

    if not check_dependencies():
        return 1

    from macron_ui_v3 import app
    from macron_voice_vad import MacronVoiceInterface

    voice = MacronVoiceInterface()
    print("[Launcher] VAD Voice inicializado")

    def open_browser():
        time.sleep(1.5)
        webbrowser.open('http://localhost:5004')

    threading.Thread(target=open_browser, daemon=True).start()

    print("\n" + "="*50)
    print("  MACRON UI v3.0 - http://localhost:5004")
    print("  Presiona Ctrl+C para detener")
    print("="*50 + "\n")

    try:
        app.run(host='0.0.0.0', port=5004, debug=False, threaded=True)
    except KeyboardInterrupt:
        print("\n[Launcher] MACRON detenido. Hasta pronto.")

    return 0

if __name__ == '__main__':
    sys.exit(main())
