"""
macron/agents/conversation.py
ConversationAgent para MACRON v3.0 - Hereda de BaseAgent
"""
import json
import os
from datetime import datetime
from pathlib import Path
from .base import BaseAgent

class ConversationAgent(BaseAgent):
    __macron_module__ = True
    __macron_name__ = "conversation"
    __version__ = "3.0"
    __dependencies__ = []
    
    def __init__(self, core=None, memory_file=None):
        super().__init__(core)
        self.memory_file = memory_file or os.path.expanduser("~/Documents/MACRON/memory.json")
        self.memory = self._load_memory()
        self.personality = {
            "name": "MACRON",
            "tone": "profesional pero amigable",
            "language": "es",
            "expertise": ["macOS", "productividad", "desarrollo", "Apple Silicon"]
        }
    
    def _load_memory(self):
        """Carga memoria desde archivo."""
        try:
            if os.path.exists(self.memory_file):
                with open(self.memory_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
        except Exception as e:
            print(f"Error cargando memoria: {e}")
        return {
            "conversations": [],
            "facts": {},
            "preferences": {},
            "created": datetime.now().isoformat()
        }
    
    def _save_memory(self):
        """Guarda memoria en archivo."""
        try:
            with open(self.memory_file, 'w', encoding='utf-8') as f:
                json.dump(self.memory, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error guardando memoria: {e}")
    
    def remember_conversation(self, user_msg, agent_msg, context=None):
        """Guarda interaccion en memoria."""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "user": user_msg,
            "agent": agent_msg,
            "context": context or {}
        }
        self.memory["conversations"].append(entry)
        if len(self.memory["conversations"]) > 100:
            self.memory["conversations"] = self.memory["conversations"][-100:]
        self._save_memory()
        return True
    
    def remember_fact(self, key, value):
        """Guarda hecho en memoria."""
        self.memory["facts"][key] = {
            "value": value,
            "timestamp": datetime.now().isoformat()
        }
        self._save_memory()
        return True
    
    def recall_fact(self, key):
        """Recupera hecho de memoria."""
        fact = self.memory["facts"].get(key)
        if fact:
            return fact["value"]
        return None
    
    def get_context(self, limit=5):
        """Obtiene contexto reciente."""
        return self.memory["conversations"][-limit:] if self.memory["conversations"] else []
    
    def set_preference(self, key, value):
        """Establece preferencia del usuario."""
        self.memory["preferences"][key] = value
        self._save_memory()
        return True
    
    def get_preference(self, key, default=None):
        """Obtiene preferencia del usuario."""
        return self.memory["preferences"].get(key, default)
    
    def analyze_sentiment(self, text):
        """Analiza sentimiento de texto."""
        positive = ["bien", "excelente", "genial", "perfecto", "gracias", "me gusta", "bueno"]
        negative = ["mal", "error", "problema", "fallo", "no funciona", "malo", "odio"]
        
        text_lower = text.lower()
        pos_count = sum(1 for p in positive if p in text_lower)
        neg_count = sum(1 for n in negative if n in text_lower)
        
        if pos_count > neg_count:
            return "positive"
        elif neg_count > pos_count:
            return "negative"
        return "neutral"
    
    def generate_response(self, user_msg, context=None):
        """Genera respuesta personalizada."""
        sentiment = self.analyze_sentiment(user_msg)
        recent = self.get_context(3)
        
        response = {
            "text": "",
            "sentiment": sentiment,
            "context_used": len(recent),
            "timestamp": datetime.now().isoformat()
        }
        
        if "hola" in user_msg.lower() or "buenos" in user_msg.lower():
            name = self.get_preference("user_name", "")
            greeting = f"Hola{name}! Soy MACRON, tu asistente para macOS. "
            greeting += "Estoy listo para ayudarte con productividad, calendario, notas y mas."
            response["text"] = greeting
        
        elif "como estas" in user_msg.lower():
            response["text"] = "Funcionando al 100% con arquitectura Dual Brain v3.0. ¿Y tú? ¿En qué puedo ayudarte hoy?"
        
        elif "que puedes hacer" in user_msg.lower() or "ayuda" in user_msg.lower():
            response["text"] = """Puedo ayudarte con:
• 📅 Calendario y eventos
• 📝 Notas y recordatorios
• 📧 Mails de Mail.app
• 📁 Archivos y Finder
• 🌐 Busquedas en Safari
• 🤖 Resumenes diarios automaticos
• 👁️ Monitoreo de carpetas
• 🧠 Memoria semantica con SecondBrain
¿Qué necesitas?"""
        
        elif "gracias" in user_msg.lower():
            response["text"] = "¡De nada! Estoy aqui para lo que necesites. 😊"
        
        elif "adios" in user_msg.lower() or "chao" in user_msg.lower():
            response["text"] = "¡Hasta luego! Guardando nuestra conversacion en memoria... 👋"
        
        else:
            response["text"] = f"Entiendo. Dime mas sobre '{user_msg[:30]}...' para poder ayudarte mejor."
        
        self.remember_conversation(user_msg, response["text"], context)
        return response
    
    def get_memory_stats(self):
        """Retorna estadisticas de memoria."""
        return {
            "conversations": len(self.memory["conversations"]),
            "facts": len(self.memory["facts"]),
            "preferences": len(self.memory["preferences"]),
            "memory_file": self.memory_file,
            "since": self.memory.get("created", "Desconocido")
        }
    
    def info(self):
        return {"name": self.name, "version": self.version, "methods": [
            "remember_conversation", "remember_fact", "recall_fact",
            "get_context", "set_preference", "get_preference",
            "analyze_sentiment", "generate_response", "get_memory_stats"
        ]}
