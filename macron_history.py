"""
MACRON History v1.0
Historial de chat persistente en SQLite
"""
import sqlite3
import os
import json
from datetime import datetime

DB_PATH = os.path.expanduser("~/Documents/MACRON/macron_history.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS conversations
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  timestamp TEXT,
                  sender TEXT,
                  message TEXT,
                  session_id TEXT)''')
    conn.commit()
    conn.close()

def save_message(sender, message, session_id="default"):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("INSERT INTO conversations (timestamp, sender, message, session_id) VALUES (?, ?, ?, ?)",
              (datetime.now().isoformat(), sender, message, session_id))
    conn.commit()
    conn.close()

def get_history(session_id="default", limit=50):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT timestamp, sender, message FROM conversations WHERE session_id = ? ORDER BY timestamp DESC LIMIT ?",
              (session_id, limit))
    rows = c.fetchall()
    conn.close()
    return rows

def search_history(query, session_id="default"):
    init_db()
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT timestamp, sender, message FROM conversations WHERE session_id = ? AND message LIKE ? ORDER BY timestamp DESC",
              (session_id, f"%{query}%"))
    rows = c.fetchall()
    conn.close()
    return rows

def export_history(format="txt", session_id="default"):
    history = get_history(session_id)
    if format == "txt":
        lines = [f"[{row[0]}] {row[1]}: {row[2]}" for row in history]
        return "\n".join(lines)
    elif format == "md":
        lines = [f"**{row[1]}** ({row[0]}):\n{row[2]}\n" for row in history]
        return "\n".join(lines)
    elif format == "json":
        return json.dumps([{"timestamp": row[0], "sender": row[1], "message": row[2]} for row in history], indent=2)
    return ""

if __name__ == "__main__":
    init_db()
    print(f"[History] DB: {DB_PATH}")
