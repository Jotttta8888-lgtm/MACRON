"""
MACRON Cache v1.0
Cache de modelos MLX para evitar descargas repetidas
"""
import os
import hashlib
import json

CACHE_DIR = os.path.expanduser("~/Documents/MACRON/.cache")

def ensure_cache_dir():
    os.makedirs(CACHE_DIR, exist_ok=True)

def get_cache_path(key):
    ensure_cache_dir()
    hashed = hashlib.md5(key.encode()).hexdigest()
    return os.path.join(CACHE_DIR, f"{hashed}.json")

def cache_exists(key):
    return os.path.exists(get_cache_path(key))

def cache_get(key):
    path = get_cache_path(key)
    if os.path.exists(path):
        with open(path, 'r') as f:
            return json.load(f)
    return None

def cache_set(key, data):
    path = get_cache_path(key)
    with open(path, 'w') as f:
        json.dump(data, f)

def cache_clear():
    import shutil
    if os.path.exists(CACHE_DIR):
        shutil.rmtree(CACHE_DIR)
    ensure_cache_dir()
    print("[Cache] Cache limpiado")

if __name__ == "__main__":
    ensure_cache_dir()
    print(f"[Cache] Directorio: {CACHE_DIR}")
