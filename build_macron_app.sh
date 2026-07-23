#!/bin/bash
set -e

APP_NAME="MACRON"
BUILD_DIR="$HOME/Documents/MACRON/MACRON_v4/.build/arm64-apple-macosx/debug"
APP_BUNDLE="$HOME/Documents/MACRON/MACRON.app"
BINARY="$BUILD_DIR/MACRON"

echo "=== Building MACRON.app ==="

# Build first
cd ~/Documents/MACRON/MACRON_v4
swift build

# Create bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/MACRON"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MACRON</string>
    <key>CFBundleIdentifier</key>
    <string>com.macron.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MACRON</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Make executable
chmod +x "$APP_BUNDLE/Contents/MacOS/MACRON"

echo "=== MACRON.app created at: $APP_BUNDLE ==="
echo "=== Launch it by double-clicking in Finder ==="
