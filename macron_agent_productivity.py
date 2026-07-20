"""
macron_agent_productivity.py
Agente autonomo de productividad para MACRON v8.1
Funcionalidades: resumen diario, alertas, sugerencias
"""
import json
from datetime import datetime, timedelta

class ProductivityAgent:
    """Agente que analiza y optimiza la productividad del usuario."""
    
    def __init__(self, core):
        self.core = core
        self.name = "ProductivityAgent"
        self.version = "1.0"
    
    def daily_summary(self):
        """Genera un resumen diario completo."""
        summary = {
            "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
            "agent": self.name,
            "sections": []
        }
        
        # 1. Calendario de hoy
        try:
            events = self.core.calendar_today()
            summary["sections"].append({
                "title": "📅 Calendario de hoy",
                "count": len(events),
                "items": [e.get("title", "Sin titulo") for e in events[:5]]
            })
        except Exception as e:
            summary["sections"].append({
                "title": "📅 Calendario de hoy",
                "error": str(e)
            })
        
        # 2. Mails no leidos
        try:
            unread = self.core.mail_unread_count()
            summary["sections"].append({
                "title": "📧 Mails",
                "unread": unread
            })
        except Exception as e:
            summary["sections"].append({
                "title": "📧 Mails",
                "error": str(e)
            })
        
        # 3. Recordatorios pendientes
        try:
            rems = self.core.reminders_pending("Recordatorios", 5)
            summary["sections"].append({
                "title": "⏰ Recordatorios pendientes",
                "count": len(rems),
                "items": [r.get("title", "Sin titulo") for r in rems]
            })
        except Exception as e:
            summary["sections"].append({
                "title": "⏰ Recordatorios pendientes",
                "error": str(e)
            })
        
        # 4. Archivos recientes
        try:
            files = self.core.finder_recent(5)
            summary["sections"].append({
                "title": "📁 Archivos recientes",
                "count": len(files),
                "items": [f.get("name", "Sin nombre") for f in files]
            })
        except Exception as e:
            summary["sections"].append({
                "title": "📁 Archivos recientes",
                "error": str(e)
            })
        
        return summary
    
    def suggest_actions(self):
        """Sugiere acciones basadas en el contexto actual."""
        suggestions = []
        
        # Sugerir revisar mails si hay muchos no leidos
        try:
            unread = self.core.mail_unread_count()
            if unread > 10:
                suggestions.append(f"📧 Tienes {unread} mails no leidos. Considera revisarlos.")
        except:
            pass
        
        # Sugerir eventos proximos
        try:
            upcoming = self.core.calendar_upcoming(1, 3)
            if upcoming:
                for e in upcoming:
                    suggestions.append(f"📅 Proximo evento: {e.get('title', '')}")
        except:
            pass
        
        # Sugerir recordatorios vencidos
        try:
            rems = self.core.reminders_pending("Recordatorios", 10)
            overdue = [r for r in rems if r.get("due") and r.get("due") != "missing value"]
            if overdue:
                suggestions.append(f"⏰ Tienes {len(overdue)} recordatorios pendientes.")
        except:
            pass
        
        return suggestions
    
    def format_summary_text(self, summary):
        """Formatea el resumen como texto legible."""
        lines = [
            f"📊 RESUMEN DIARIO — {summary['date']}",
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

# -- CLI TEST --
if __name__ == "__main__":
    import sys
    sys.path.insert(0, '.')
    import macron_core
    
    print("=" * 50)
    print("MACRON Productivity Agent v8.1")
    print("=" * 50)
    
    core = macron_core.MacronCore()
    agent = ProductivityAgent(core)
    
    print("\n📊 GENERANDO RESUMEN DIARIO...")
    summary = agent.daily_summary()
    print(agent.format_summary_text(summary))
    
    print("\n💡 SUGERENCIAS:")
    suggestions = agent.suggest_actions()
    if suggestions:
        for s in suggestions:
            print(f"   {s}")
    else:
        print("   No hay sugerencias por ahora.")
    
    print("\n" + "=" * 50)
    print("Productivity Agent listo")
    print("=" * 50)
