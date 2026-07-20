import os

os.makedirs('MACRON.app/Contents/MacOS', exist_ok=True)
os.makedirs('MACRON.app/Contents/Resources', exist_ok=True)

launcher = "#!/bin/bash\ncd \"$HOME/Documents/MACRON\"\nsource venv/bin/activate\nexec python3 macron_tkinter.py\n"
with open('MACRON.app/Contents/MacOS/MACRON', 'w') as f:
    f.write(launcher)
os.chmod('MACRON.app/Contents/MacOS/MACRON', 0o755)

plist = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>MACRON</string>
    <key>CFBundleDisplayName</key><string>MACRON</string>
    <key>CFBundleIdentifier</key><string>com.macron.app</string>
    <key>CFBundleVersion</key><string>4.0.0</string>
    <key>CFBundleShortVersionString</key><string>4.0.0</string>
    <key>CFBundleExecutable</key><string>MACRON</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSBackgroundOnly</key><false/>
</dict>
</plist>"""
with open('MACRON.app/Contents/Info.plist', 'w') as f:
    f.write(plist)

print("OK")
