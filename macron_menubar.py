import rumps
import subprocess
import os

class MACRONMenuBar(rumps.App):
    def __init__(self):
        # Usar icono original (no template)
        icon_path = os.path.expanduser("~/Documents/MACRON/icon_1024x1024.png")
        super().__init__("MACRON", title=None, icon=icon_path, template=False)
        self.menu = [
            "Abrir MACRON",
            "Estado del servidor",
            None,
            "Reiniciar servidor",
            "Detener MACRON",
            None,
            "Acerca de MACRON",
            "Salir"
        ]
    
    @rumps.clicked("Abrir MACRON")
    def open_macron(self, _):
        subprocess.Popen(["open", "/Applications/MACRON.app"])
        rumps.notification("MACRON", "Abierto", "La app se está iniciando...")
    
    @rumps.clicked("Estado del servidor")
    def check_status(self, _):
        import urllib.request
        try:
            req = urllib.request.Request("http://127.0.0.1:5004/api/status")
            with urllib.request.urlopen(req, timeout=2) as resp:
                if resp.status == 200:
                    rumps.notification("MACRON", "Estado", "Servidor en línea ✅")
                else:
                    rumps.notification("MACRON", "Estado", "Servidor con problemas ⚠️")
        except:
            rumps.notification("MACRON", "Estado", "Servidor apagado ❌")
    
    @rumps.clicked("Reiniciar servidor")
    def restart_server(self, _):
        subprocess.run(["pkill", "-f", "macron_launcher"])
        subprocess.Popen(["open", "/Applications/MACRON.app"])
        rumps.notification("MACRON", "Reiniciando", "Servidor reiniciado...")
    
    @rumps.clicked("Detener MACRON")
    def stop_macron(self, _):
        subprocess.run(["pkill", "-f", "macron_launcher"])
        rumps.notification("MACRON", "Detenido", "MACRON se ha cerrado")
    
    @rumps.clicked("Acerca de MACRON")
    def about(self, _):
        rumps.alert("MACRON v4.3", "Agente IA local para macOS\nApple Silicon / MLX\n\nDesarrollado por Juan Camilo")
    
    @rumps.clicked("Salir")
    def quit(self, _):
        rumps.quit_application()

if __name__ == "__main__":
    MACRONMenuBar().run()
