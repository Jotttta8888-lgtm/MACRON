import os
import subprocess

# Ruta a la app
app_path = "/Applications/MACRON.app"

# Agregar a elementos de inicio usando osascript (AppleScript)
script = f'''
tell application "System Events"
    make login item at end with properties {{path:"{app_path}", hidden:false}}
end tell
'''

result = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
if result.returncode == 0:
    print("✅ MACRON agregado a elementos de inicio")
else:
    print(f"Error: {result.stderr}")
