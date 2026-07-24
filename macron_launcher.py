#!/usr/bin/env python3
"""
MACRON Launcher v3.0
Inicia el sistema completo con todas las mejoras
"""
import os
import sys
import time
import subprocess
import webbrowser
from pathlib import Path

def print_banner():
    print("\n" + "="*60)
    print("  🤖 MACRON v3.0 - DUAL BRAIN ARCHITECTURE")
    print("="*60)
    print("  Apple Silicon • MLX • Neural Engine • FAISS")
    print("="*60 + "\n")

def check_venv():
    if not hasattr(sys, 'real_prefix') and not (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        print("⚠️  No estás en el virtual environment")
        print("   Ejecuta: source venv/bin/activate")
        return False
    return True

def start_api():
    print("🚀 Iniciando API Server...")
    print("   URL: http://localhost:5001")
    print("   Auth: X-API-Key header required")
    print("   WebSocket: ws://localhost:5001/ws/chat")
    print("   SSE: http://localhost:5001/api/stream")
    print()
    
    # Iniciar server en background
    proc = subprocess.Popen(
        [sys.executable, "-m", "macron.api.server"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=os.path.expanduser("~/Documents/MACRON")
    )
    
    # Esperar a que inicie
    time.sleep(2)
    
    # Verificar que está corriendo
    import urllib.request
    try:
        req = urllib.request.Request('http://localhost:5001/api/auth/status')
        with urllib.request.urlopen(req, timeout=5) as resp:
            print("✅ API Server iniciado correctamente")
            return proc
    except Exception as e:
        print(f"⚠️  API Server puede estar iniciándose... ({e})")
        return proc

def show_menu():
    print("\n" + "="*60)
    print("  📋 MENÚ PRINCIPAL")
    print("="*60)
    print("  1. 🌐 Abrir Web UI (http://localhost:5001)")
    print("  2. 📊 Ver estado del sistema")
    print("  3. 📧 Ver mails no leídos")
    print("  4. 🔗 Ver tabs de Safari")
    print("  5. 📁 Ver archivos del Desktop")
    print("  6. 📅 Ver eventos de hoy")
    print("  7. 📝 Ver notas")
    print("  8. ✅ Ver recordatorios pendientes")
    print("  9. 🤖 Resumen diario (ProductivityAgent)")
    print("  10. 👁️ Reporte de monitoreo (MonitorAgent)")
    print("  11. 💬 Chat con MACRON (ConversationAgent)")
    print("  12. 🧠 Probar SecondBrain (memoria semántica)")
    print("  13. 🧪 Ejecutar tests")
    print("  0. ❌ Salir")
    print("="*60)

def api_call(path, method='GET', data=None):
    import urllib.request
    import json
    
    # Leer API key
    key_file = os.path.expanduser("~/.macron_api_key")
    if not os.path.exists(key_file):
        import secrets
        new_key = secrets.token_hex(32)
        with open(key_file, "w") as f:
            f.write(new_key)
        print(f"   API Key generada: {new_key[:16]}...")
    with open(key_file) as f:
        api_key = f.read().strip()
    
    url = f'http://localhost:5001{path}'
    headers = {
        'X-API-Key': api_key,
        'Content-Type': 'application/json'
    }
    
    if method == 'POST':
        req = urllib.request.Request(url, data=json.dumps(data).encode(), headers=headers, method='POST')
    else:
        req = urllib.request.Request(url, headers=headers)
    
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        return {'error': str(e)}

def main():
    print_banner()
    
    if not check_venv():
        return
    
    # Iniciar API
    api_proc = start_api()
    
    try:
        while True:
            show_menu()
            choice = input("\n  Selecciona una opción: ").strip()
            
            if choice == '0':
                print("\n👋 Cerrando MACRON...")
                api_proc.terminate()
                break
            
            elif choice == '1':
                print("\n🌐 Abriendo Web UI...")
                webbrowser.open('http://localhost:5001')
            
            elif choice == '2':
                print("\n📊 Estado del sistema:")
                result = api_call('/api/status')
                print(f"   Engine: {result.get('engine', 'N/A')}")
                print(f"   Módulos activos: {result.get('modules_active', 0)}")
                print(f"   Total módulos: {result.get('modules_total', 0)}")
                hw = result.get('hardware', {})
                print(f"   Arquitectura: {hw.get('architecture', 'N/A')}")
                print(f"   Second Brain: {hw.get('second_brain', 'N/A')}")
            
            elif choice == '3':
                print("\n📧 Mails no leídos:")
                result = api_call('/api/mail/inbox?limit=5')
                emails = result.get('emails', [])
                print(f"   Total: {result.get('count', 0)}")
                for e in emails[:3]:
                    print(f"   • {e.get('subject', 'Sin asunto')[:50]}")
                    print(f"     De: {e.get('sender', 'Desconocido')[:40]}")
            
            elif choice == '4':
                print("\n🔗 Tabs de Safari:")
                result = api_call('/api/safari/tabs')
                tabs = result.get('tabs', [])
                active = result.get('active', {})
                print(f"   Total tabs: {result.get('count', 0)}")
                print(f"   Tab activa: {active.get('title', 'N/A')[:50]}")
                print(f"   URL: {active.get('url', 'N/A')[:60]}")
                for t in tabs[:3]:
                    print(f"   • {t.get('title', 'Sin título')[:40]}")
            
            elif choice == '5':
                print("\n📁 Archivos del Desktop:")
                result = api_call('/api/finder/desktop')
                files = result.get('files', [])
                print(f"   Total archivos: {result.get('count', 0)}")
                for f in files[:5]:
                    print(f"   • {f.get('name', 'Sin nombre')[:40]} ({f.get('size_human', '?')})")
            
            elif choice == '6':
                print("\n📅 Eventos de hoy:")
                result = api_call('/api/calendar/today')
                events = result.get('events', [])
                print(f"   Total eventos: {result.get('count', 0)}")
                for e in events[:3]:
                    print(f"   • {e.get('title', 'Sin título')}")
                    print(f"     Inicio: {e.get('start', 'N/A')}")
            
            elif choice == '7':
                print("\n📝 Notas:")
                result = api_call('/api/notes/list?limit=5')
                notes = result.get('notes', [])
                print(f"   Total notas: {result.get('count', 0)}")
                for n in notes[:5]:
                    print(f"   • {n.get('title', 'Sin título')[:50]}")
            
            elif choice == '8':
                print("\n✅ Recordatorios pendientes:")
                result = api_call('/api/reminders/pending?limit=5')
                rems = result.get('reminders', [])
                print(f"   Total pendientes: {result.get('count', 0)}")
                for r in rems[:5]:
                    print(f"   • {r.get('title', 'Sin título')[:50]}")
                    if r.get('due'):
                        print(f"     Vence: {r.get('due')}")
            
            elif choice == '9':
                print("\n🤖 Resumen diario (ProductivityAgent):")
                result = api_call('/api/agent/summary')
                print(f"   Fecha: {result.get('date', 'N/A')}")
                print(f"   Agente: {result.get('agent', 'N/A')} v{result.get('version', '?')}")
                for section in result.get('sections', []):
                    title = section.get('title', 'Sin título')
                    if 'error' in section:
                        print(f"   ❌ {title}: {section['error']}")
                    else:
                        count = section.get('count', section.get('unread', '?'))
                        print(f"   ✅ {title}: {count}")
            
            elif choice == '10':
                print("\n👁️ Reporte de monitoreo (MonitorAgent):")
                result = api_call('/api/monitor/report')
                print(f"   Fecha: {result.get('date', 'N/A')}")
                print(f"   Agente: {result.get('agent', 'N/A')} v{result.get('version', '?')}")
                for folder in result.get('folders', []):
                    path = folder.get('path', 'N/A')
                    recent = folder.get('recent', {})
                    print(f"   📁 {path}")
                    print(f"      Archivos: {recent.get('count', 0)}")
            
            elif choice == '11':
                print("\n💬 Chat con MACRON (escribe 'salir' para volver):")
                while True:
                    msg = input("   Tú: ").strip()
                    if msg.lower() in ('salir', 'exit', 'q'):
                        break
                    result = api_call('/api/chat', 'POST', {'message': msg})
                    print(f"   🤖 MACRON: {result.get('text', 'Error')}")
            
            elif choice == '12':
                print("\n🧠 SecondBrain - Memoria semántica:")
                from macron.infrastructure.brain import SecondBrain
                brain = SecondBrain()
                print(f"   Memorias guardadas: {brain.count()}")
                
                text = input("   Escribe algo para recordar: ").strip()
                if text:
                    mid = brain.remember(text, source='launcher', category='user')
                    print(f"   ✅ Guardado con ID: {mid}")
                    
                    query = input("   Escribe algo para buscar: ").strip()
                    if query:
                        results = brain.recall(query)
                        print(f"   🔍 Resultados: {len(results)}")
                        for r in results[:3]:
                            print(f"   • {r.get('content', 'N/A')[:60]}...")
            
            elif choice == '13':
                print("\n🧪 Ejecutando tests...")
                result = subprocess.run(
                    [sys.executable, '-m', 'pytest', 'tests/', '-q'],
                    capture_output=True,
                    text=True,
                    cwd=os.path.expanduser("~/Documents/MACRON")
                )
                print(result.stdout)
                if result.returncode == 0:
                    print("✅ Todos los tests pasaron")
                else:
                    print("❌ Algunos tests fallaron")
            
            else:
                print("\n⚠️ Opción no válida")
            
            input("\n  Presiona Enter para continuar...")
    
    except KeyboardInterrupt:
        print("\n\n👋 Cerrando MACRON...")
        api_proc.terminate()

if __name__ == '__main__':
    main()
