"""
MACRON Offline v1.0
Verifica y asegura funcionamiento sin conexion a internet
"""
import socket
import os
import json

def check_internet():
    """Verifica si hay conexion a internet"""
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=3)
        return True
    except OSError:
        return False

def get_offline_status():
    """Obtiene estado de recursos offline"""
    status = {
        "internet": check_internet(),
        "models_cached": False,
        "documents_available": False,
        "voice_models_ready": False
    }
    
    # Verificar modelos cacheados
    cache_dir = os.path.expanduser("~/Documents/MACRON/.cache")
    if os.path.exists(cache_dir) and len(os.listdir(cache_dir)) > 0:
        status["models_cached"] = True
    
    # Verificar documentos RAG
    docs_dir = os.path.expanduser("~/Documents/MACRON/docs")
    if os.path.exists(docs_dir) and len(os.listdir(docs_dir)) > 0:
        status["documents_available"] = True
    
    # Verificar modelos de voz
    voice_dir = os.path.expanduser("~/Documents/MACRON/.mlx_whisper")
    if os.path.exists(voice_dir):
        status["voice_models_ready"] = True
    
    return status

def ensure_offline_ready():
    """Asegura que todo este listo para modo offline"""
    status = get_offline_status()
    
    recommendations = []
    if not status["models_cached"]:
        recommendations.append("Descargar modelos MLX para uso offline")
    if not status["documents_available"]:
        recommendations.append("Agregar documentos a la carpeta docs/")
    if not status["voice_models_ready"]:
        recommendations.append("Descargar modelos de voz Whisper")
    
    return {
        "ready": all(status.values()),
        "status": status,
        "recommendations": recommendations
    }

if __name__ == "__main__":
    result = ensure_offline_ready()
    print(f"Modo offline listo: {result['ready']}")
    if result['recommendations']:
        print("Recomendaciones:")
        for rec in result['recommendations']:
            print(f"  - {rec}")
