"""
MACRON Multi-User v1.0
Perfiles separados con datos aislados
"""
import os
import sqlite3
import json

USERS_DIR = os.path.expanduser("~/Documents/MACRON/users")

def get_user_dir(user_id):
    user_dir = os.path.join(USERS_DIR, user_id)
    os.makedirs(user_dir, exist_ok=True)
    return user_dir

def get_user_db(user_id):
    user_dir = get_user_dir(user_id)
    return os.path.join(user_dir, "data.db")

def init_user(user_id, name="Usuario"):
    user_dir = get_user_dir(user_id)
    config_path = os.path.join(user_dir, "config.json")
    
    if not os.path.exists(config_path):
        config = {
            "name": name,
            "created": __import__('datetime').datetime.now().isoformat(),
            "theme": "auto",
            "language": "es"
        }
        with open(config_path, 'w') as f:
            json.dump(config, f)
    
    # Crear DB personal
    db_path = get_user_db(user_id)
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS messages
                 (id INTEGER PRIMARY KEY, timestamp TEXT, sender TEXT, text TEXT)''')
    conn.commit()
    conn.close()
    
    return config_path

def list_users():
    if not os.path.exists(USERS_DIR):
        return []
    return [d for d in os.listdir(USERS_DIR) if os.path.isdir(os.path.join(USERS_DIR, d))]

if __name__ == "__main__":
    init_user("default", "Usuario Principal")
    print(f"Usuarios: {list_users()}")
