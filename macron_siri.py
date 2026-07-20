"""
MACRON Siri Integration v1.0
Permite controlar MACRON mediante Siri/Shortcuts
"""
import sys
import requests
import json

def send_message_to_macron(message):
    """Envía un mensaje a MACRON vía API"""
    try:
        response = requests.post(
            "http://127.0.0.1:5004/api/chat",
            json={"message": message},
            timeout=30
        )
        data = response.json()
        return data.get("text", "No pude obtener respuesta")
    except Exception as e:
        return f"Error: {str(e)}"

def get_status():
    """Obtiene estado de MACRON"""
    try:
        response = requests.get("http://127.0.0.1:5004/api/status", timeout=5)
        data = response.json()
        return f"MACRON está en línea. Modelo: {data.get('hardware', {}).get('model', 'desconocido')}"
    except:
        return "MACRON no está respondiendo"

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 macron_siri.py [mensaje|status]")
        return
    
    command = sys.argv[1]
    
    if command == "status":
        print(get_status())
    else:
        # Enviar mensaje
        message = " ".join(sys.argv[1:])
        response = send_message_to_macron(message)
        print(response)

if __name__ == "__main__":
    main()
