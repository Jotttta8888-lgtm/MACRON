
"""
MACRON Core v6.6.2
API unificada que expone TODAS las funcionalidades del sistema.
Conecta los 15 modulos huerfanos a la UI via wrappers de funciones.
"""
import os
import sys
import json
import time
import logging
from datetime import datetime

# ── CONFIGURACION ─────────────────────────────────────────────
MACRON_DIR = os.path.expanduser("~/Documents/MACRON")
LOG_FILE = os.path.join(MACRON_DIR, "macron.log")

# ── LOGGING CENTRALIZADO ──────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("MACRON.Core")

# ── IMPORTS CON GRACEFUL DEGRADATION ──────────────────────────
def _safe_import(module_name):
    """Importa un modulo con manejo de errores graceful."""
    try:
        return __import__(module_name)
    except Exception as e:
        logger.warning(f"Modulo no disponible: {module_name} - {e}")
        return None

# Core funcionalidades (siempre disponibles)
try:
    from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator, MacronConfig, MacronLogger
    CORE_AVAILABLE = True
    logger.info("Core MACRON_FUNCIONALIDADES_v2 cargado")
except Exception as e:
    CORE_AVAILABLE = False
    logger.error(f"Core no disponible: {e}")

# Modulos huerfanos — importados como modulos, no clases
_mod_history = _safe_import("macron_history")
_mod_export = _safe_import("macron_export")
_mod_search = _safe_import("macron_search")
_mod_cache = _safe_import("macron_cache")
_mod_memory = _safe_import("macron_memory_optimizer")
_mod_models = _safe_import("macron_model_selector")
_mod_notifications = _safe_import("macron_notifications")
_mod_hotkey = _safe_import("macron_hotkey")
_mod_widget = _safe_import("macron_widget")
_mod_siri = _safe_import("macron_siri")
_mod_plugins = _safe_import("macron_plugins")
_mod_analytics = _safe_import("macron_analytics")
_mod_offline = _safe_import("macron_offline")
_mod_encryption = _safe_import("macron_encryption")
_mod_multiuser = _safe_import("macron_multiuser")
_mod_calendar = _safe_import("macron_calendar")
_mod_focus = _safe_import("macron_focus")

# ── CLASE PRINCIPAL: API UNIFICADA ──────────────────────────────
class MacronCore:
    """
    API unificada de MACRON.
    Expone todas las funcionalidades como metodos simples.
    """
    
    def __init__(self):
        self.start_time = time.time()
        self.orchestrator = None
        self._init_core()
        self._init_modules()
        logger.info("MacronCore inicializado")
    
    def _init_core(self):
        """Inicializa el nucleo si esta disponible."""
        if CORE_AVAILABLE:
            try:
                self.orchestrator = MacronOrchestrator()
                logger.info("Orchestrator inicializado")
            except Exception as e:
                logger.error(f"Error inicializando orchestrator: {e}")
    
    def _init_modules(self):
        """Inicializa modulos huerfanos (solo tracking de disponibilidad)."""
        self.modules = {
            "history": _mod_history is not None,
            "export": _mod_export is not None,
            "search": _mod_search is not None,
            "cache": _mod_cache is not None,
            "memory": _mod_memory is not None,
            "models": _mod_models is not None,
            "notifications": _mod_notifications is not None,
            "hotkey": _mod_hotkey is not None,
            "widget": _mod_widget is not None,
            "siri": _mod_siri is not None,
            "plugins": _mod_plugins is not None,
            "analytics": _mod_analytics is not None,
            "offline": _mod_offline is not None,
            "encryption": _mod_encryption is not None,
            "multiuser": _mod_multiuser is not None,
            "calendar": _mod_calendar is not None,
            "focus": _mod_focus is not None,
        }
        for name, available in self.modules.items():
            if available:
                logger.info(f"Modulo '{name}' disponible")
    
    # ── ESTADO DEL SISTEMA ──────────────────────────────────────
    def get_status(self):
        """Devuelve estado completo del sistema."""
        uptime = int(time.time() - self.start_time)
        active_modules = [k for k, v in self.modules.items() if v]
        return {
            "version": "6.6.2",
            "core_available": CORE_AVAILABLE,
            "uptime_seconds": uptime,
            "uptime_formatted": f"{uptime//3600}h {(uptime%3600)//60}m {uptime%60}s",
            "modules_total": len(self.modules),
            "modules_active": len(active_modules),
            "modules_inactive": len(self.modules) - len(active_modules),
            "active": active_modules,
            "inactive": [k for k, v in self.modules.items() if not v],
            "timestamp": datetime.now().isoformat()
        }
    
    def get_health(self):
        """Health check rapido."""
        status = self.get_status()
        healthy = status["core_available"] and status["modules_active"] >= 5
        return {
            "healthy": healthy,
            "status": "ok" if healthy else "degraded",
            **status
        }
    
    # ── CHAT / LLM ──────────────────────────────────────────────
    def chat(self, message, context=None):
        """Envia mensaje al LLM."""
        if self.orchestrator and hasattr(self.orchestrator, 'chat'):
            try:
                return self.orchestrator.chat(message, context)
            except Exception as e:
                logger.error(f"Error en chat: {e}")
                return {"error": str(e), "response": "Error procesando mensaje"}
        return {"error": "Orchestrator no disponible", "response": "Sistema no inicializado"}
    
    # ── HISTORIAL ───────────────────────────────────────────────
    def history_list(self, limit=50):
        """Lista historial de conversaciones."""
        if _mod_history and hasattr(_mod_history, 'get_history'):
            try:
                return _mod_history.get_history(limit=limit)
            except Exception as e:
                logger.warning(f"history_list error: {e}")
        return []
    
    def history_save(self, sender, message, session_id="default"):
        """Guarda mensaje en historial."""
        if _mod_history and hasattr(_mod_history, 'save_message'):
            try:
                return _mod_history.save_message(sender, message, session_id)
            except Exception as e:
                logger.warning(f"history_save error: {e}")
        return False
    
    # ── EXPORTAR ─────────────────────────────────────────────────
    def export_conversation(self, session_id="default", fmt="json"):
        """Exporta conversacion a formato."""
        if _mod_export:
            try:
                if fmt == "txt" and hasattr(_mod_export, 'export_to_txt'):
                    return _mod_export.export_to_txt(session_id)
                elif fmt == "md" and hasattr(_mod_export, 'export_to_md'):
                    return _mod_export.export_to_md(session_id)
                elif fmt == "json" and hasattr(_mod_export, 'export_to_json'):
                    return _mod_export.export_to_json(session_id)
            except Exception as e:
                logger.warning(f"export error: {e}")
        return {"error": "Export no disponible"}
    
    # ── BUSQUEDA ─────────────────────────────────────────────────
    def search(self, query, session_id="default"):
        """Busca en conversaciones."""
        if _mod_search and hasattr(_mod_search, 'search_chat'):
            try:
                return _mod_search.search_chat(query, session_id)
            except Exception as e:
                logger.warning(f"search error: {e}")
        return []
    
    # ── CACHE ────────────────────────────────────────────────────
    def cache_clear(self):
        """Limpia cache de modelos."""
        if _mod_cache and hasattr(_mod_cache, 'cache_clear'):
            try:
                return _mod_cache.cache_clear()
            except Exception as e:
                logger.warning(f"cache_clear error: {e}")
        return False
    
    # ── MEMORIA ────────────────────────────────────────────────
    def memory_optimize(self):
        """Optimiza uso de RAM."""
        if _mod_memory and hasattr(_mod_memory, 'optimize_memory'):
            try:
                return _mod_memory.optimize_memory()
            except Exception as e:
                logger.warning(f"memory_optimize error: {e}")
        return {"status": "not_available"}
    
    # ── MODELOS ────────────────────────────────────────────────
    def models_list(self):
        """Lista modelos disponibles."""
        if _mod_models and hasattr(_mod_models, 'list_models'):
            try:
                return _mod_models.list_models()
            except Exception as e:
                logger.warning(f"models_list error: {e}")
        return ["llama-3.2-1b", "mistral-7b", "phi-3"]
    
    def model_switch(self, model_key):
        """Cambia modelo activo."""
        if _mod_models and hasattr(_mod_models, 'set_current_model'):
            try:
                return _mod_models.set_current_model(model_key)
            except Exception as e:
                logger.warning(f"model_switch error: {e}")
        return False
    
    # ── NOTIFICACIONES ─────────────────────────────────────────
    def notify(self, title, message):
        """Envia notificacion nativa de macOS."""
        if _mod_notifications and hasattr(_mod_notifications, 'send_notification'):
            try:
                return _mod_notifications.send_notification(title, message)
            except Exception as e:
                logger.warning(f"notify error: {e}")
        try:
            os.system(f'osascript -e \'display notification "{message}" with title "{title}"\'')
            return True
        except:
            return False
    
    # ── WIDGET ───────────────────────────────────────────────────
    def widget_show(self):
        """Muestra widget flotante."""
        if _mod_widget and hasattr(_mod_widget, 'show_widget'):
            try:
                return _mod_widget.show_widget()
            except Exception as e:
                logger.warning(f"widget_show error: {e}")
        return False
    
    # ── PLUGINS ────────────────────────────────────────────────
    def plugins_list(self):
        """Lista plugins disponibles."""
        if _mod_plugins and hasattr(_mod_plugins, 'list_plugins'):
            try:
                return _mod_plugins.list_plugins()
            except Exception as e:
                logger.warning(f"plugins_list error: {e}")
        return []
    
    def plugin_run(self, name, *args, **kwargs):
        """Ejecuta un plugin."""
        if _mod_plugins and hasattr(_mod_plugins, 'execute_plugin'):
            try:
                return _mod_plugins.execute_plugin(name, *args, **kwargs)
            except Exception as e:
                logger.warning(f"plugin_run error: {e}")
        return {"error": "Plugins no disponible"}
    
    # ── ANALYTICS ───────────────────────────────────────────────
    def analytics_summary(self, days=7):
        """Resumen de analytics."""
        if _mod_analytics and hasattr(_mod_analytics, 'get_stats'):
            try:
                return _mod_analytics.get_stats(days)
            except Exception as e:
                logger.warning(f"analytics error: {e}")
        return {"total_messages": 0, "total_voice_commands": 0, "total_errors": 0}
    
    # ── OFFLINE ────────────────────────────────────────────────
    def offline_status(self):
        """Estado del modo offline."""
        if _mod_offline and hasattr(_mod_offline, 'get_offline_status'):
            try:
                return _mod_offline.get_offline_status()
            except Exception as e:
                logger.warning(f"offline error: {e}")
        return {"ready": False, "models_cached": False, "documents_available": False}
    
    # ── ENCRIPTACION ───────────────────────────────────────────
    def encrypt(self, text):
        """Encripta texto."""
        if _mod_encryption and hasattr(_mod_encryption, 'encrypt'):
            try:
                return _mod_encryption.encrypt(text)
            except Exception as e:
                logger.warning(f"encrypt error: {e}")
        return {"error": "Encryption no disponible"}
    
    def decrypt(self, token):
        """Desencripta texto."""
        if _mod_encryption and hasattr(_mod_encryption, 'decrypt'):
            try:
                return _mod_encryption.decrypt(token)
            except Exception as e:
                logger.warning(f"decrypt error: {e}")
        return {"error": "Encryption no disponible"}
    
    # ── MULTI-USUARIO ──────────────────────────────────────────
    def users_list(self):
        """Lista usuarios."""
        if _mod_multiuser and hasattr(_mod_multiuser, 'list_users'):
            try:
                return _mod_multiuser.list_users()
            except Exception as e:
                logger.warning(f"users_list error: {e}")
        return ["default"]
    
    def user_init(self, user_id, name="Usuario"):
        """Inicializa usuario."""
        if _mod_multiuser and hasattr(_mod_multiuser, 'init_user'):
            try:
                return _mod_multiuser.init_user(user_id, name)
            except Exception as e:
                logger.warning(f"user_init error: {e}")
        return False
    
    # ── CALENDAR ───────────────────────────────────────────────
    def calendar_add_event(self, title, start_date, notes=""):
        """Agrega evento al calendario."""
        if _mod_calendar and hasattr(_mod_calendar, 'add_calendar_event'):
            try:
                return _mod_calendar.add_calendar_event(title, start_date, notes)
            except Exception as e:
                logger.warning(f"calendar_add_event error: {e}")
        return False
    
    def reminder_add(self, title, notes=""):
        """Agrega recordatorio."""
        if _mod_calendar and hasattr(_mod_calendar, 'add_reminder'):
            try:
                return _mod_calendar.add_reminder(title, notes)
            except Exception as e:
                logger.warning(f"reminder_add error: {e}")
        return False
    
    # ── FOCUS (POMODORO) ───────────────────────────────────────
    def focus_toggle(self):
        """Activa/desactiva modo Focus."""
        if _mod_focus and hasattr(_mod_focus, 'toggle_focus'):
            try:
                return _mod_focus.toggle_focus()
            except Exception as e:
                logger.warning(f"focus_toggle error: {e}")
        return "Focus no disponible"
    
    def focus_status(self):
        """Estado del modo Focus."""
        if _mod_focus:
            try:
                active = _mod_focus.is_focus_mode() if hasattr(_mod_focus, 'is_focus_mode') else False
                remaining = 0
                if active and hasattr(_mod_focus, 'get_focus_time_remaining'):
                    remaining = _mod_focus.get_focus_time_remaining()
                return {"active": active, "remaining_minutes": remaining}
            except Exception as e:
                logger.warning(f"focus_status error: {e}")
        return {"active": False, "remaining_minutes": 0}
    
    # ── SIRI ───────────────────────────────────────────────────
    def siri_send(self, message):
        """Envia mensaje via integracion Siri."""
        if _mod_siri and hasattr(_mod_siri, 'send_message_to_macron'):
            try:
                return _mod_siri.send_message_to_macron(message)
            except Exception as e:
                logger.warning(f"siri_send error: {e}")
        return {"error": "Siri no disponible"}

# ── SINGLETON ───────────────────────────────────────────────────
_core_instance = None

def get_core():
    """Devuelve instancia singleton de MacronCore."""
    global _core_instance
    if _core_instance is None:
        _core_instance = MacronCore()
    return _core_instance

# ── CLI TEST ────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 50)
    print("MACRON Core v6.6.2 — Test de Inicializacion")
    print("=" * 50)
    
    core = get_core()
    status = core.get_status()
    
    print(f"\n📊 Estado del Sistema:")
    print(f"   Version: {status['version']}")
    print(f"   Core: {'✅ OK' if status['core_available'] else '❌ No disponible'}")
    print(f"   Uptime: {status['uptime_formatted']}")
    print(f"   Modulos activos: {status['modules_active']}/{status['modules_total']}")
    
    print(f"\n✅ Modulos activos: {', '.join(status['active']) if status['active'] else 'Ninguno'}")
    if status['inactive']:
        print(f"⚠️  Modulos inactivos: {', '.join(status['inactive'])}")
    
    health = core.get_health()
    print(f"\n🏥 Health Check: {health['status'].upper()}")
    
    print("\n🔔 Test notificacion...")
    result = core.notify("MACRON Core", "Sistema inicializado correctamente")
    print(f"   Resultado: {'✅ OK' if result else '❌ Fallo'}")
    
    print("\n🍅 Test Focus...")
    focus_st = core.focus_status()
    print(f"   Estado: {'Activo' if focus_st['active'] else 'Inactivo'}")
    
    print("\n" + "=" * 50)
    print("MacronCore v6.6.2 listo para usar")
    print("=" * 50)
