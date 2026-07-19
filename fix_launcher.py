import os
launcher = "#!/bin/bash\ncd \"$HOME/Documents/MACRON\"\nsource venv/bin/activate\nexec python3 macron_autonomous_v2.py\n"
with open('/Applications/MACRON.app/Contents/MacOS/MACRON', 'w') as f:
    f.write(launcher)
os.chmod('/Applications/MACRON.app/Contents/MacOS/MACRON', 0o755)
print("OK")
