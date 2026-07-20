"""
MACRON Analytics v1.0
Dashboard de metricas y estadisticas de uso
"""
import os
import json
import sqlite3
from datetime import datetime, timedelta

DB_PATH = os.path.expanduser("~/Documents/MACRON/macron_analytics.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS events
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  timestamp TEXT,
                  event_type TEXT,
                  data TEXT)''')
    conn.commit()
    conn.close()

def log_event(event_type, data=None):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT INTO events (timestamp, event_type, data) VALUES (?, ?, ?)",
              (datetime.now().isoformat(), event_type, json.dumps(data) if data else "{}"))
    conn.commit()
    conn.close()

def get_stats(days=7):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    since = (datetime.now() - timedelta(days=days)).isoformat()
    
    # Total de mensajes
    c.execute("SELECT COUNT(*) FROM events WHERE event_type = 'message' AND timestamp > ?", (since,))
    total_messages = c.fetchone()[0]
    
    # Total de comandos de voz
    c.execute("SELECT COUNT(*) FROM events WHERE event_type = 'voice' AND timestamp > ?", (since,))
    total_voice = c.fetchone()[0]
    
    # Errores
    c.execute("SELECT COUNT(*) FROM events WHERE event_type = 'error' AND timestamp > ?", (since,))
    total_errors = c.fetchone()[0]
    
    # Uso por dia
    c.execute("SELECT date(timestamp), COUNT(*) FROM events WHERE timestamp > ? GROUP BY date(timestamp)", (since,))
    daily_usage = c.fetchall()
    
    conn.close()
    
    return {
        "period_days": days,
        "total_messages": total_messages,
        "total_voice_commands": total_voice,
        "total_errors": total_errors,
        "daily_usage": daily_usage,
        "uptime_hours": 0  # Se calcularia con un monitor
    }

def export_stats(format="json", days=7):
    stats = get_stats(days)
    if format == "json":
        return json.dumps(stats, indent=2)
    elif format == "txt":
        lines = [
            f"MACRON Analytics - Ultimos {days} dias",
            f"Total mensajes: {stats['total_messages']}",
            f"Total comandos de voz: {stats['total_voice_commands']}",
            f"Total errores: {stats['total_errors']}",
            "Uso diario:"
        ]
        for day, count in stats['daily_usage']:
            lines.append(f"  {day}: {count} eventos")
        return "\n".join(lines)
    return ""

if __name__ == "__main__":
    init_db()
    print("Modulo de analytics cargado")
    print(export_stats("txt", 7))
