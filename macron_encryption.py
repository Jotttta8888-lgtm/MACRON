"""
MACRON Encryption v1.0
Cifrado de historial y configuraciones
"""
import os
import hashlib
from cryptography.fernet import Fernet

KEY_FILE = os.path.expanduser("~/Documents/MACRON/.secret_key")

def get_or_create_key():
    if os.path.exists(KEY_FILE):
        with open(KEY_FILE, 'rb') as f:
            return f.read()
    key = Fernet.generate_key()
    os.makedirs(os.path.dirname(KEY_FILE), exist_ok=True)
    with open(KEY_FILE, 'wb') as f:
        f.write(key)
    return key

def encrypt(data):
    f = Fernet(get_or_create_key())
    return f.encrypt(data.encode()).decode()

def decrypt(token):
    f = Fernet(get_or_create_key())
    return f.decrypt(token.encode()).decode()

if __name__ == "__main__":
    test = "Hola MACRON"
    enc = encrypt(test)
    dec = decrypt(enc)
    print(f"Original: {test}")
    print(f"Encriptado: {enc[:50]}...")
    print(f"Desencriptado: {dec}")
