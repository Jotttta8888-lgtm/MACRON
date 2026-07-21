#!/usr/bin/env python3
"""
health_check.py
Script de health check para MACRON v6.6.2
Prueba todos los endpoints automaticamente
"""
import urllib.request
import urllib.error
import json
import sys

BASE_URL = "http://localhost:5001"
TIMEOUT = 10

ENDPOINTS_GET = [
    ("/api/status", "Estado del sistema"),
    ("/api/history", "Historial"),
    ("/api/plugins", "Plugins"),
    ("/api/analytics", "Analytics"),
    ("/api/calendar/today", "Calendario hoy"),
    ("/api/finder/desktop", "Finder desktop"),
    ("/api/finder/downloads", "Finder downloads"),
    ("/api/mail/unread", "Mail no leidos"),
    ("/api/safari/tabs", "Safari tabs"),
    ("/api/notes/list", "Notas"),
    ("/api/reminders/pending", "Recordatorios"),
    ("/api/agent/summary", "Resumen agente"),
    ("/api/monitor/report", "Reporte monitor"),
]

ENDPOINTS_POST = [
    ("/api/chat", {"message": "Hola MACRON"}, "Chat IA"),
    ("/api/notify", {"title": "Test", "message": "Health check"}, "Notificacion"),
    ("/api/focus/toggle", {"enabled": True}, "Focus toggle"),
    ("/api/finder/search", {"query": "macron"}, "Finder search"),
    ("/api/mail/search", {"query": "test"}, "Mail search"),
    ("/api/notes/search", {"query": "macron"}, "Notas search"),
    ("/api/calendar/search", {"query": "test"}, "Calendario search"),
]

def test_get(endpoint, name):
    """Prueba endpoint GET."""
    try:
        req = urllib.request.Request(f"{BASE_URL}{endpoint}", method='GET')
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            data = json.loads(response.read().decode('utf-8'))
            return True, data
    except Exception as e:
        return False, str(e)

def test_post(endpoint, payload, name):
    """Prueba endpoint POST."""
    try:
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            f"{BASE_URL}{endpoint}",
            data=data,
            headers={'Content-Type': 'application/json'},
            method='POST'
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            result = json.loads(response.read().decode('utf-8'))
            return True, result
    except Exception as e:
        return False, str(e)

def main():
    print("=" * 60)
    print("  MACRON Health Check v6.6.2")
    print(f"  URL: {BASE_URL}")
    print("=" * 60)
    
    passed = 0
    failed = 0
    
    print("\n--- GET Endpoints ---")
    for endpoint, name in ENDPOINTS_GET:
        ok, result = test_get(endpoint, name)
        status = "✅ PASS" if ok else "❌ FAIL"
        print(f"  {status} {name:25s} {endpoint}")
        if ok:
            passed += 1
        else:
            failed += 1
            print(f"      Error: {result}")
    
    print("\n--- POST Endpoints ---")
    for endpoint, payload, name in ENDPOINTS_POST:
        ok, result = test_post(endpoint, payload, name)
        status = "✅ PASS" if ok else "❌ FAIL"
        print(f"  {status} {name:25s} {endpoint}")
        if ok:
            passed += 1
        else:
            failed += 1
            print(f"      Error: {result}")
    
    print("\n" + "=" * 60)
    print(f"  Resultado: {passed} pasados, {failed} fallidos")
    print(f"  Total: {passed + failed} endpoints probados")
    print("=" * 60)
    
    return 0 if failed == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
