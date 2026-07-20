"""
MACRON Notifications v1.0
Notificaciones nativas de macOS para MACRON
"""
import os
from pync import Notifier

class MacronNotifications:
    def __init__(self):
        self.app_name = "MACRON"
    
    def notify(self, title, message, sound=True):
        """Envía una notificación nativa de macOS"""
        try:
            Notifier.notify(
                message,
                title=title,
                app_name=self.app_name,
                sound=sound
            )
        except Exception as e:
            print(f"[Notificaciones] Error: {e}")
    
    def server_started(self):
        self.notify("MACRON", "Servidor iniciado y listo ✅")
    
    def server_stopped(self):
        self.notify("MACRON", "Servidor detenido ❌")
    
    def new_message(self, sender, text):
        self.notify(f"Nuevo mensaje de {sender}", text[:100])
    
    def error(self, error_msg):
        self.notify("MACRON - Error", error_msg)
    
    def welcome(self):
        self.notify("MACRON v4.5", "Bienvenido. Tu asistente IA local está listo.", sound=False)

if __name__ == "__main__":
    # Test
    n = MacronNotifications()
    n.welcome()
