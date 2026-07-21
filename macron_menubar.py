#!/usr/bin/env python3
"""
macron_menubar.py
Menu de barra para MACRON en macOS
"""
import rumps
import subprocess
import os
import urllib.request
import json

class MACRONMenuBar(rumps.App):
    def __init__(self):
        super(MACRONMenuBar, self).__init__(
            name="MACRON",
            title="M",
            icon=None,
            quit_button='Salir'
        )
        self.server_pid = None
        self.server_running = False
        
    @rumps.clicked('Iniciar Servidor')
    def start_server(self, sender):
        if self.server_running:
            rumps.notification("MACRON", "Info", "El servidor ya esta corriendo")
            return
        
        macron_dir = os.path.expanduser("~/Documents/MACRON")
        script_path = os.path.join(macron_dir, "start_macron.sh")
        
        if not os.path.exists(script_path):
            rumps.notification("MACRON", "Error", "No se encontro start_macron.sh")
            return
        
        try:
            # Iniciar servidor en background
            subprocess.Popen(
                ["bash", script_path],
                cwd=macron_dir,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            self.server_running = True
            rumps.notification("MACRON", "OK", "Servidor iniciado en http://localhost:5001")
        except Exception as e:
            rumps.notification("MACRON", "Error", str(e))
    
    @rumps.clicked('Abrir en Safari')
    def open_safari(self, sender):
        subprocess.run(["open", "http://localhost:5001"])
    
    @rumps.clicked('Health Check')
    def health_check(self, sender):
        try:
            req = urllib.request.Request("http://localhost:5001/api/status", timeout=5)
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode('utf-8'))
                modules = data.get('modules_active', 0)
                rumps.notification("MACRON", "Status", f"{modules} modulos activos")
        except Exception as e:
            rumps.notification("MACRON", "Error", "Servidor no responde")
    
    @rumps.clicked('Detener Servidor')
    def stop_server(self, sender):
        try:
            subprocess.run(["lsof", "-ti:5001"], capture_output=True)
            subprocess.run(["bash", "-c", "lsof -ti:5001 | xargs kill -9 2>/dev/null"], check=False)
            self.server_running = False
            rumps.notification("MACRON", "OK", "Servidor detenido")
        except Exception as e:
            rumps.notification("MACRON", "Error", str(e))

if __name__ == '__main__':
    app = MACRONMenuBar()
    app.run()
