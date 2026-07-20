"""
macron_agent_conversation.py
Agente conversacional avanzado para MACRON v8.5
Funcionalidades: memoria, contexto, personalidad, aprendizaje
"""
import json
import os
from datetime import datetime
from pathlib import Path

class ConversationAgent:
    """Agente con memoria a largo plazo y personalidad."""
    
    def __init__(self, core, memory_file=None):
        self.core = core
        self.name = "ConversationAgent"
        self.version = "1.0"
        self.memory_file = memory_file or os.path.expanduser("~/Documents/MACRON/memory.json")
        self.memory = self._load_memory()
        self.personality = {
            "name": "MACRON",
            "tone": "profesional pero amigable",
            "language": "es",
            "expertise": ["macOS", "productividad", "desarrollo", "Apple Silicon"]
        }
    
    def _load_memory(self):
        """Carga la memoria desde archivo."""
        try:
            if os.path.exists(self.memory_file):
                with open(self.memory_file, 'r') as f:
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
        """Guarda la memoria en archivo."""
        try:
            with open(self.memory_file, 'w') as f:
                json.dump(self.memory, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Error guardando memoria: {e}")
    
    def remember_conversation(self, user_msg, agent_msg, context=None):
        """Guarda una interaccion en la memoria."""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "user": user_msg,
            "agent": agent_msg,
            "context": context or {}
        }
        self.memory["conversations"].append(entry)
        # Mantener solo las ultimas 100 conversaciones
        if len(self.memory["conversations"]) > 100:
            self.memory["conversations"] = self.memory["conversations"][-100:]
        self._save_memory()
        return True
    
    def remember_fact(self, key, value):
        """Guarda un hecho en la memoria."""
        self.memory["facts"][key] = {
            "value": value,
            "timestamp": datetime.now().isoformat()
        }
        self._save_memory()
        return True
    
    def recall_fact(self, key):
        """Recupera un hecho de la memoria."""
        fact = self.memory["facts"].get(key)
        if fact:
            return fact["value"]
        return None
    
    def get_context(self, limit=5):
        """Obtiene el contexto reciente de conversaciones."""
        return self.memory["conversations"][-limit:] if self.memory["conversations"] else []
    
    def set_preference(self, key, value):
        """Establece una preferencia del usuario."""
        self.memory["preferences"][key] = value
        self._save_memory()
        return True
    
    def get_preference(self, key, default=None):
        """Obtiene una preferencia del usuario."""
        return self.memory["preferences"].get(key, default)
    
    def analyze_sentiment(self, text):
        """Analiza el sentimiento de un texto (simple)."""
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
        """Genera una respuesta personalizada basada en memoria y contexto."""
        # Analizar sentimiento
        sentiment = self.analyze_sentiment(user_msg)
        
        # Obtener contexto reciente
        recent = self.get_context(3)
        
        # Construir respuesta
        response = {
            "text": "",
            "sentiment": sentiment,
            "context_used": len(recent),
            "timestamp": datetime.now().isoformat()
        }
        
        # Respuestas basadas en patrones
        if "hola" in user_msg.lower() or "buenos" in user_msg.lower():
            name = self.get_preference("user_name", "")
            greeting = f"Hola{name}! Soy MACRON, tu asistente para macOS. "
            greeting += "Estoy listo para ayudarte con productividad, calendario, notas y mas."
            response["text"] = greeting
        
        elif "como estas" in user_msg.lower():
            response["text"] = "Funcionando al 100% con 27 modulos activos. ¿Y tú? ¿En qué puedo ayudarte hoy?"
        
        elif "que puedes hacer" in user_msg.lower() or "ayuda" in user_msg.lower():
            response["text"] = """Puedo ayudarte con:
• 📅 Calendario y eventos
• 📝 Notas y recordatorios
• 📧 Mails de Mail.app
• 📁 Archivos y Finder
• 🌐 Busquedas en Safari
• 🤖 Resumenes diarios automaticos
• 👁️ Monitoreo de carpetas
• 🔌 Plugins personalizados
¿Qué necesitas?"""
        
        elif "gracias" in user_msg.lower():
            response["text"] = "¡De nada! Estoy aqui para lo que necesites. 😊"
        
        elif "adios" in user_msg.lower() or "chao" in user_msg.lower():
            response["text"] = "¡Hasta luego! Guardando nuestra conversacion en memoria... 👋"
        
        else:
            # Respuesta generica con contexto
            response["text"] = f"Entiendo. Dime mas sobre '{user_msg[:30]}...' para poder ayudarte mejor."
        
        # Guardar en memoria
        self.remember_conversation(user_msg, response["text"], context)
        
        return response
    
    def get_memory_stats(self):
        """Retorna estadisticas de la memoria."""
        return {
            "conversations": len(self.memory["conversations"]),
            "facts": len(self.memory["facts"]),
            "preferences": len(self.memory["preferences"]),
            "memory_file": self.memory_file,
            "since": self.memory.get("created", "Desconocido")
        }

# -- CLI TEST --
if __name__ == "__main__":
    import sys
    sys.path.insert(0, '.')
    import macron_core
    
    print("=" * 50)
    print("MACRON Conversation Agent v8.5")
    print("=" * 50)
    
    core = macron_core.MacronCore()
    agent = ConversationAgent(core)
    
    print(f"\n🧠 MEMORIA: {agent.memory_file}")
    stats = agent.get_memory_stats()
    print(f"   Conversaciones: {stats['conversations']}")
    print(f"   Hechos: {stats['facts']}")
    print(f"   Preferencias: {stats['preferences']}")
    
    print("\n💬 PRUEBA DE CONVERSACION:")
    tests = [
        "Hola MACRON",
        "Que puedes hacer?",
        "Gracias por tu ayuda",
        "Adios"
    ]
    
    for msg in tests:
        print(f"\n👤 Usuario: {msg}")
        resp = agent.generate_response(msg)
        print(f"🤖 MACRON: {resp['text']}")
        print(f"   Sentimiento: {resp['sentiment']}")
    
    print("\n📊 ESTADISTICAS FINALES:")
    stats = agent.get_memory_stats()
    print(f"   Conversaciones guardadas: {stats['conversations']}")
    
    print("\n" + "=" * 50)
    print("Conversation Agent listo")
    print("=" * 50)
