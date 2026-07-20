"""
macron/agents/productivity.py
ProductivityAgent para MACRON v3.0 - Hereda de BaseAgent
"""
import json
from datetime import datetime, timedelta
from .base import BaseAgent

class ProductivityAgent(BaseAgent):
    __macron_module__ = True
    __macron_name__ = "productivity"
    __version__ = "3.0"
    __dependencies__ = ["calendar", "mail", "reminders", "finder"]
    
    def __init__(self, core=None):
        super().__init__(core)
    
    def daily_summary(self):
        """Genera resumen diario completo."""
        summary = {
            "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "agent": self.name,
            "version": self.version,
            "sections": []
        }
        
        # 1. Calendario de hoy
        try:
            calendar = self._get_adapter("calendar")
            if calendar:
                events = calendar.get_today_events()
                summary["sections"].append({
                    "title": "📅 Calendario de hoy",
                    "count": len(events),
                    "items": [e.get("title", "Sin titulo") for e in events[:5]]
                })
            else:
                summary["sections"].append({"title": "📅 Calendario de hoy", "error": "Adapter no disponible"})
        except Exception as e:
            summary["sections"].append({"title": "📅 Calendario de hoy", "error": str(e)})
        
        # 2. Mails no leidos
        try:
            mail = self._get_adapter("mail")
            if mail:
                unread = mail.get_unread_count()
                summary["sections"].append({
                    "title": "📧 Mails",
                    "unread": unread
                })
            else:
                summary["sections"].append({"title": "📧 Mails", "error": "Adapter no disponible"})
        except Exception as e:
            summary["sections"].append({"title": "📧 Mails", "error": str(e)})
        
        # 3. Recordatorios pendientes
        try:
            reminders = self._get_adapter("reminders")
            if reminders:
                rems = reminders.get_reminders("Recordatorios", completed=False, limit=5)
                summary["sections"].append({
                    "title": "⏰ Recordatorios pendientes",
                    "count": len(rems),
                    "items": [r.get("title", "Sin titulo") for r in rems]
                })
            else:
                summary["sections"].append({"title": "⏰ Recordatorios pendientes", "error": "Adapter no disponible"})
        except Exception as e:
            summary["sections"].append({"title": "⏰ Recordatorios pendientes", "error": str(e)})
        
        # 4. Archivos recientes
        try:
            finder = self._get_adapter("finder")
            if finder:
                files = finder.get_recent_files(5)
                summary["sections"].append({
                    "title": "📁 Archivos recientes",
                    "count": len(files),
                    "items": [f.get("name", "Sin nombre") for f in files]
                })
            else:
                summary["sections"].append({"title": "📁 Archivos recientes", "error": "Adapter no disponible"})
        except Exception as e:
            summary["sections"].append({"title": "📁 Archivos recientes", "error": str(e)})
        
        return summary
    
    def suggest_actions(self):
        """Sugiere acciones basadas en contexto actual."""
        suggestions = []
        
        try:
            mail = self._get_adapter("mail")
            if mail:
                unread = mail.get_unread_count()
                if unread > 10:
                    suggestions.append(f"📧 Tienes {unread} mails no leidos. Considera revisarlos.")
        except:
            pass
        
        try:
            calendar = self._get_adapter("calendar")
            if calendar:
                upcoming = calendar.get_upcoming_events(1, 3)
                if upcoming:
                    for e in upcoming:
                        suggestions.append(f"📅 Proximo evento: {e.get('title', '')}")
        except:
            pass
        
        try:
            reminders = self._get_adapter("reminders")
            if reminders:
                rems = reminders.get_reminders("Recordatorios", completed=False, limit=10)
                overdue = [r for r in rems if r.get("due") and r.get("due") != "missing value"]
                if overdue:
                    suggestions.append(f"⏰ Tienes {len(overdue)} recordatorios pendientes.")
        except:
            pass
        
        return suggestions
    
    def format_summary_text(self, summary):
        """Formatea resumen como texto legible."""
        lines = [
            f"📊 RESUMEN DIARIO — {summary['date']}",
            f"   Agente: {summary['agent']} v{summary['version']}",
            "=" * 50,
            ""
        ]
        
        for section in summary["sections"]:
            lines.append(section["title"])
            if "error" in section:
                lines.append(f"   ⚠️ {section['error']}")
            elif "count" in section:
                lines.append(f"   Total: {section['count']}")
                for item in section.get("items", []):
                    lines.append(f"   • {item[:40]}...")
            elif "unread" in section:
                lines.append(f"   No leidos: {section['unread']}")
            lines.append("")
        
        return "\n".join(lines)
    
    def info(self):
        return {"name": self.name, "version": self.version, "methods": [
            "daily_summary", "suggest_actions", "format_summary_text"
        ]}
