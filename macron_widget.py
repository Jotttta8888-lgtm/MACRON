"""
MACRON Widget v1.0
Ventana flotante siempre visible (always on top)
"""
import tkinter as tk
from tkinter import scrolledtext
import requests

class MacronWidget:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("MACRON Widget")
        self.root.geometry("400x300")
        self.root.configure(bg="#0a0a0f")
        self.root.attributes('-topmost', True)  # Siempre visible
        self.root.attributes('-alpha', 0.95)   # Ligeramente transparente
        
        # Header
        header = tk.Frame(self.root, bg="#12121a", height=30)
        header.pack(fill="x")
        tk.Label(header, text="MACRON", font=("SF Pro Display", 12, "bold"), 
                bg="#12121a", fg="#00d4aa").pack(side="left", padx=10)
        
        # Quick input
        self.input_field = tk.Entry(self.root, font=("SF Pro Text", 12),
                                     bg="#1a1a2e", fg="#e0e0e0",
                                     insertbackground="#e0e0e0")
        self.input_field.pack(fill="x", padx=10, pady=5)
        self.input_field.bind("<Return>", self.quick_chat)
        
        # Response area
        self.response = tk.Label(self.root, text="Listo...", font=("SF Pro Text", 11),
                                bg="#0a0a0f", fg="#888888", wraplength=380)
        self.response.pack(fill="both", expand=True, padx=10, pady=5)
    
    def quick_chat(self, event=None):
        text = self.input_field.get().strip()
        if not text:
            return
        self.input_field.delete(0, "end")
        self.response.config(text="Pensando...", fg="#00d4aa")
        
        import threading
        threading.Thread(target=self._send, args=(text,), daemon=True).start()
    
    def _send(self, text):
        try:
            response = requests.post("http://127.0.0.1:5004/api/chat", 
                                     json={"message": text}, timeout=30)
            data = response.json()
            reply = data.get("text", "Error")
            self.root.after(0, lambda: self.response.config(text=reply, fg="#e0e0e0"))
        except Exception as e:
            self.root.after(0, lambda: self.response.config(text=f"Error: {str(e)}", fg="#ff4444"))
    
    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    MacronWidget().run()
