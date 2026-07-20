import tkinter as tk
from tkinter import ttk, scrolledtext
import threading
import requests
import json

class MacronApp:
    def __init__(self, root):
        self.root = root
        self.root.title("MACRON v4.0 - Agente IA Local")
        self.root.geometry("800x600")
        self.root.configure(bg="#0a0a0f")
        
        # Configurar estilo oscuro
        self.style = ttk.Style()
        self.style.configure("TFrame", background="#0a0a0f")
        self.style.configure("TLabel", background="#0a0a0f", foreground="#e0e0e0")
        
        # Header
        header = tk.Frame(root, bg="#12121a", height=50)
        header.pack(fill="x", padx=0, pady=0)
        
        title = tk.Label(header, text="MACRON", font=("SF Pro Display", 20, "bold"), 
                        bg="#12121a", fg="#00d4aa")
        title.pack(side="left", padx=20, pady=10)
        
        status = tk.Label(header, text="● En linea", font=("SF Pro Text", 12), 
                         bg="#12121a", fg="#00d4aa")
        status.pack(side="right", padx=20, pady=10)
        
        # Chat area
        self.chat_frame = tk.Frame(root, bg="#0a0a0f")
        self.chat_frame.pack(fill="both", expand=True, padx=20, pady=10)
        
        self.chat_text = scrolledtext.ScrolledText(self.chat_frame, wrap=tk.WORD,
                                                    font=("SF Pro Text", 13),
                                                    bg="#12121a", fg="#e0e0e0",
                                                    insertbackground="#e0e0e0",
                                                    relief="flat", state="disabled")
        self.chat_text.pack(fill="both", expand=True)
        
        # Input area
        input_frame = tk.Frame(root, bg="#12121a", height=60)
        input_frame.pack(fill="x", padx=20, pady=10)
        input_frame.pack_propagate(False)
        
        self.input_field = tk.Entry(input_frame, font=("SF Pro Text", 14),
                                     bg="#1a1a2e", fg="#e0e0e0",
                                     insertbackground="#e0e0e0",
                                     relief="flat", bd=10)
        self.input_field.pack(side="left", fill="both", expand=True, padx=(0, 10))
        self.input_field.bind("<Return>", self.send_message)
        
        # Voice button
        voice_btn = tk.Button(input_frame, text="🎤", font=("SF Pro Text", 18),
                               bg="#1a1a2e", fg="#00d4aa", relief="flat",
                               cursor="hand2", command=self.toggle_voice)
        voice_btn.pack(side="right", padx=(0, 10))
        
        # Send button
        send_btn = tk.Button(input_frame, text="→", font=("SF Pro Text", 18, "bold"),
                              bg="#00d4aa", fg="#0a0a0f", relief="flat",
                              cursor="hand2", command=self.send_message)
        send_btn.pack(side="right")
        
        # Welcome message
        self.add_message("MACRON", "¡Hola! Soy MACRON, tu asistente IA local para macOS. Escribe un mensaje o usa el microfono para hablar conmigo.", "bot")
        
        self.is_recording = False
        
    def add_message(self, sender, text, msg_type):
        self.chat_text.configure(state="normal")
        
        if msg_type == "user":
            color = "#00d4aa"
            align = "right"
        else:
            color = "#888888"
            align = "left"
        
        self.chat_text.insert("end", f"\n{sender}\n", ("sender",))
        self.chat_text.insert("end", f"{text}\n\n", ("text",))
        
        self.chat_text.tag_configure("sender", foreground=color, font=("SF Pro Text", 11, "bold"))
        self.chat_text.tag_configure("text", foreground="#e0e0e0", font=("SF Pro Text", 13))
        
        self.chat_text.configure(state="disabled")
        self.chat_text.see("end")
        
    def send_message(self, event=None):
        text = self.input_field.get().strip()
        if not text:
            return
        
        self.input_field.delete(0, "end")
        self.add_message("Tu", text, "user")
        
        # Enviar al servidor en thread separado
        threading.Thread(target=self._chat_request, args=(text,), daemon=True).start()
        
    def _chat_request(self, text):
        try:
            response = requests.post("http://localhost:5004/api/chat", 
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
            response = requests.post("http://localhost:5004/api/voice/transcribe", 
                                     timeout=30)
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

if __name__ == "__main__":
    root = tk.Tk()
    app = MacronApp(root)
    root.mainloop()
