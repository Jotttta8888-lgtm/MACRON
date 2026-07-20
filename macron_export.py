"""
MACRON Export v1.0
Exporta conversaciones a PDF, Markdown, TXT
"""
import os
from datetime import datetime
from macron_history import get_history

def export_to_txt(session_id="default", output_path=None):
    if output_path is None:
        output_path = os.path.expanduser(f"~/Documents/MACRON/export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
    
    history = get_history(session_id)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("=" * 50 + "\n")
        f.write("MACRON - Exportacion de conversacion\n")
        f.write(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 50 + "\n\n")
        
        for row in reversed(history):  # Orden cronologico
            f.write(f"[{row[0]}] {row[1]}:\n")
            f.write(f"{row[2]}\n\n")
    
    return output_path

def export_to_md(session_id="default", output_path=None):
    if output_path is None:
        output_path = os.path.expanduser(f"~/Documents/MACRON/export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md")
    
    history = get_history(session_id)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# Conversacion MACRON\n\n")
        f.write(f"**Fecha:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\\n\\n")
        f.write("---\\n\\n")
        
        for row in reversed(history):
            sender = "Usuario" if row[1] == "Tu" else "MACRON"
            f.write(f"## {sender} ({row[0]})\\n\\n")
            f.write(f"{row[2]}\\n\\n")
            f.write("---\\n\\n")
    
    return output_path

def export_to_json(session_id="default", output_path=None):
    import json
    if output_path is None:
        output_path = os.path.expanduser(f"~/Documents/MACRON/export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
    
    history = get_history(session_id)
    data = {
        "export_date": datetime.now().isoformat(),
        "session_id": session_id,
        "messages": [
            {"timestamp": row[0], "sender": row[1], "message": row[2]}
            for row in reversed(history)
        ]
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    return output_path

if __name__ == "__main__":
    print("Formatos de exportacion disponibles:")
    print("  1. TXT - Texto plano")
    print("  2. MD - Markdown")
    print("  3. JSON - JSON estructurado")
