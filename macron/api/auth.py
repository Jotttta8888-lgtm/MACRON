"""
macron/api/auth.py
Autenticación simple para MACRON API
"""
import os
import secrets
from functools import wraps
from flask import request, jsonify

# Generar o cargar API key
def get_api_key():
    """Obtiene la API key desde archivo o genera una nueva."""
    key_file = os.path.expanduser("~/.macron_api_key")
    
    if os.path.exists(key_file):
        with open(key_file, 'r') as f:
            return f.read().strip()
    
    # Generar nueva key
    new_key = secrets.token_urlsafe(32)
    os.makedirs(os.path.dirname(key_file), exist_ok=True)
    with open(key_file, 'w') as f:
        f.write(new_key)
    
    print(f"[AUTH] Nueva API key generada: {new_key[:8]}... (guardada en {key_file})")
    return new_key

API_KEY = get_api_key()

def require_auth(f):
    """Decorador que requiere API key en header X-API-Key."""
    @wraps(f)
    def decorated(*args, **kwargs):
        provided = request.headers.get('X-API-Key', '')
        if not provided:
            return jsonify({'error': 'API key requerida. Usa header X-API-Key'}), 401
        if provided != API_KEY:
            return jsonify({'error': 'API key inválida'}), 403
        return f(*args, **kwargs)
    return decorated

def auth_status():
    """Retorna estado de autenticación (sin exponer la key)."""
    return {
        'enabled': True,
        'key_prefix': API_KEY[:8] + '...',
        'key_file': os.path.expanduser("~/.macron_api_key")
    }
