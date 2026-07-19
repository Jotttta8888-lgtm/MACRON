import os
import sys
import threading
import time
import tkinter as tk
from tkinter import scrolledtext
import requests

# ============================================
# PARTE 1: LANZAR SERVIDOR macron_ui_v3.py
# ============================================

def start_macron_server():
    """Importa y ejecuta el servidor de macron_ui_v3.py"""
    # Guardar argv original
    original_argv = sys.argv
    sys.argv = ['macron_ui_v3.py']
    
    # Importar el modulo (esto ejecuta todo el codigo a nivel de modulo)
    import macron_ui_v3
    
    # Restaurar argv
    sys.argv = original_argv
    
    # El servidor ya deberia estar corriendo si macron_ui_v3 tiene app.run() en if __name__
    # Pero como no lo tiene, necesitamos lanzarlo manualmente
    macron_ui_v3.app.run(host='127.0.0.1', port=5004, debug=False, threaded=True, use_reloader=False)

# ============================================
# PARTE 2: UI TKINTER
# ============================================

class MacronApp:
    def __init__(self, root):
        self.root = root
        self.root.title("MACRON v4.0 - Agente IA Local")
        self.root.geometry("800x600")
        self.root.configure(bg="#0a0a0f")
        
        header = tk.Frame(root, bg="#12121a", height=50)
        header.pack(fill="x", padx=0, pady=0)
        title = tk.Label(header, text="MACRON", font=("SF Pro Display", 20, "bold"), 
                        bg="#12121a", fg="#00d4aa")
        title.pack(side="left", padx=20, pady=10)
        status = tk.Label(header, text="● En linea", font=("SF Pro Text", 12), 
                         bg="#12121a", fg="#00d4aa")
        status.pack(side="right", padx=20, pady=10)
        
        self.chat_frame = tk.Frame(root, bg="#0a0a0f")
        self.chat_frame.pack(fill="both", expand=True, padx=20, pady=10)
        self.chat_text = scrolledtext.ScrolledText(self.chat_frame, wrap=tk.WORD,
                                                    font=("SF Pro Text", 13),
                                                    bg="#12121a", fg="#e0e0e0",
                                                    insertbackground="#e0e0e0",
                                                    relief="flat", state="disabled")
        self.chat_text.pack(fill="both", expand=True)
        self.chat_text.tag_configure("sender_user", foreground="#00d4aa", font=("SF Pro Text", 11, "bold"))
        self.chat_text.tag_configure("sender_bot", foreground="#888888", font=("SF Pro Text", 11, "bold"))
        self.chat_text.tag_configure("text", foreground="#e0e0e0", font=("SF Pro Text", 13))
        
        input_frame = tk.Frame(root, bg="#12121a", height=60)
        input_frame.pack(fill="x", padx=20, pady=10)
        input_frame.pack_propagate(False)
        self.input_field = tk.Entry(input_frame, font=("SF Pro Text", 14),
                                     bg="#1a1a2e", fg="#e0e0e0",
                                     insertbackground="#e0e0e0",
                                     relief="flat", bd=10)
        self.input_field.pack(side="left", fill="both", expand=True, padx=(0, 10))
        self.input_field.bind("<Return>", self.send_message)
        voice_btn = tk.Button(input_frame, text="🎤", font=("SF Pro Text", 18),
                               bg="#1a1a2e", fg="#00d4aa", relief="flat",
                               cursor="hand2", command=self.toggle_voice)
        voice_btn.pack(side="right", padx=(0, 10))
        send_btn = tk.Button(input_frame, text="→", font=("SF Pro Text", 18, "bold"),
                              bg="#00d4aa", fg="#0a0a0f", relief="flat",
                              cursor="hand2", command=self.send_message)
        send_btn.pack(side="right")
        
        self.add_message("MACRON", "¡Hola! Soy MACRON, tu asistente IA local para macOS. Escribe un mensaje o usa el microfono para hablar conmigo.", "bot")
        self.is_recording = False
        
    def add_message(self, sender, text, msg_type):
        self.chat_text.configure(state="normal")
        tag = "sender_user" if msg_type == "user" else "sender_bot"
        self.chat_text.insert("end", f"\n{sender}\n", (tag,))
        self.chat_text.insert("end", f"{text}\n\n", ("text",))
        self.chat_text.configure(state="disabled")
        self.chat_text.see("end")
        
    def send_message(self, event=None):
        text = self.input_field.get().strip()
        if not text:
            return
        self.input_field.delete(0, "end")
        self.add_message("Tu", text, "user")
        threading.Thread(target=self._chat_request, args=(text,), daemon=True).start()
        
    def _chat_request(self, text):
        try:
            response = requests.post("http://127.0.0.1:5004/api/chat", 
                                     json={"message": text}, timeout=60)
            data = response.json()
            reply = data.get("text", "Error en respuesta")
            self.root.after(0, lambda: self.add_message("MACRON", reply, "bot"))
        except Exception as e:
            self.root.after(0, lambda: self.add_message("MACRON", f"Error: {str(e)}", "bot"))
            
    def toggle_voice(self):
        if self.is_recording:
            return
        self.is_recording = True
        threading.Thread(target=self._voice_request, daemon=True).start()
        
    def _voice_request(self):
        try:
            self.root.after(0, lambda: self.add_message("MACRON", "🎤 Escuchando...", "bot"))
            response = requests.post("http://127.0.0.1:5004/api/voice/transcribe", timeout=30)
            data = response.json()
            text = data.get("text", "")
            if text:
                self.root.after(0, lambda: self.add_message("Tu", text, "user"))
                self._chat_request(text)
            else:
                self.root.after(0, lambda: self.add_message("MACRON", "No entendi. Intenta de nuevo.", "bot"))
        except Exception as e:
            self.root.after(0, lambda: self.add_message("MACRON", f"Error de voz: {str(e)}", "bot"))
        finally:
            self.is_recording = False

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    print("=" * 50)
    print("  MACRON v4.0 - Modo Autonomo")
    print("  Iniciando servidor + UI...")
    print("=" * 50)
    
    # Iniciar servidor en thread de fondo
    server_thread = threading.Thread(target=start_macron_server, daemon=True)
    server_thread.start()
    
    # Esperar a que el servidor arranque
    print("[INIT] Esperando servidor...")
    for i in range(60):
        try:
            requests.get("http://127.0.0.1:5004/api/status", timeout=1)
            print("[INIT] Servidor listo!")
            break
        except:
            time.sleep(1)
    else:
        print("[WARN] Timeout esperando servidor, continuando...")
    
    # Iniciar UI
    print("[INIT] Abriendo interfaz...")
    root = tk.Tk()
    app = MacronApp(root)
    root.mainloop()
