"""
MACRON Model Selector v1.0
Permite cambiar entre diferentes modelos MLX
"""
import os

AVAILABLE_MODELS = {
    "llama-3.2-1b": {
        "name": "Llama 3.2 1B",
        "repo": "mlx-community/Llama-3.2-1B-Instruct-4bit",
        "description": "Rápido, bueno para tareas simples",
        "ram_gb": 2
    },
    "llama-3.2-3b": {
        "name": "Llama 3.2 3B",
        "repo": "mlx-community/Llama-3.2-3B-Instruct-4bit",
        "description": "Balance velocidad/calidad",
        "ram_gb": 4
    },
    "mistral-7b": {
        "name": "Mistral 7B",
        "repo": "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
        "description": "Más potente, más lento",
        "ram_gb": 6
    },
    "phi-3-mini": {
        "name": "Phi-3 Mini",
        "repo": "mlx-community/Phi-3-mini-4k-instruct-4bit",
        "description": "Microsoft, buen rendimiento",
        "ram_gb": 3
    }
}

DEFAULT_MODEL = "llama-3.2-1b"

def get_model_info(model_key):
    return AVAILABLE_MODELS.get(model_key, AVAILABLE_MODELS[DEFAULT_MODEL])

def list_models():
    return AVAILABLE_MODELS

def get_current_model():
    # Leer de config
    config_path = os.path.expanduser("~/Documents/MACRON/.model_config")
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return f.read().strip()
    return DEFAULT_MODEL

def set_current_model(model_key):
    if model_key not in AVAILABLE_MODELS:
        return False
    config_path = os.path.expanduser("~/Documents/MACRON/.model_config")
    with open(config_path, 'w') as f:
        f.write(model_key)
    return True

if __name__ == "__main__":
    print("Modelos disponibles:")
    for key, info in list_models().items():
        print(f"  {key}: {info['name']} ({info['description']}) - {info['ram_gb']}GB RAM")
