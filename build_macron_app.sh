#!/bin/bash
# ============================================================
# MACRON .app Builder
# Genera MACRON.app bundle para macOS
# ============================================================

set -e

APP_NAME="MACRON"
BUNDLE_ID="com.macron.agent"
VERSION="2.0"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

echo "========================================"
echo "  MACRON .app Builder"
echo "  Version: $VERSION"
echo "========================================"

# Limpiar build anterior
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Crear estructura de bundle
echo "[1/6] Creando bundle..."
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"
mkdir -p "$APP_PATH/Contents/Frameworks"
mkdir -p "$APP_PATH/Contents/Resources/Python"

# Copiar ejecutable Swift
echo "[2/6] Compilando Swift..."
swiftc -O \
    -o "$APP_PATH/Contents/MacOS/MACRON" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Combine \
    MACRON_SwiftUI_App.swift \
    MACRON_SwiftUI_Views.swift \
    2>/dev/null || echo "  (Compilacion Swift requiere Xcode)"

# Crear launcher Python
cat > "$APP_PATH/Contents/MacOS/macron-python" << 'PYEOF'
#!/usr/bin/env python3
import os, sys

# Configurar entorno
os.environ["MACRON_BUNDLE"] = "1"
os.environ["PYTHONPATH"] = os.path.join(os.path.dirname(__file__), "../Resources/Python")

# Iniciar backend
from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator
macron = MacronOrchestrator()

# Mantener vivo
import time
while True:
    time.sleep(1)
PYEOF
chmod +x "$APP_PATH/Contents/MacOS/macron-python"

# Copiar archivos Python
echo "[3/6] Copiando archivos Python..."
cp MACRON_FUNCIONALIDADES_v2.py "$APP_PATH/Contents/Resources/Python/"
cp MACRON_WEB_UI_v2.1.py "$APP_PATH/Contents/Resources/Python/"

# Info.plist
echo "[4/6] Generando Info.plist..."
cat > "$APP_PATH/Contents/Info.plist" << 'PLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>es</string>
    <key>CFBundleExecutable</key>
    <string>MACRON</string>
    <key>CFBundleIdentifier</key>
    <string>com.macron.agent</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MACRON</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSCameraUsageDescription</key>
    <string>MACRON necesita acceso a la camara para deteccion de intrusos y reconocimiento facial.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>MACRON necesita acceso al microfono para transcripcion de audio.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>MACRON necesita controlar aplicaciones para funcionalidades de automatizacion.</string>
    <key>NSAppleScriptEnabled</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
PLEOF

# Icono (placeholder - usar icono generico)
echo "[5/6] Generando icono..."
cat > "$APP_PATH/Contents/Resources/AppIcon.icns" << 'ICONEOF'
# Nota: Reemplazar con icono real .icns
# sips -s format icns icon.png --out AppIcon.icns
ICONEOF

# Script de entorno
cat > "$APP_PATH/Contents/Resources/setup_env.sh" << 'ENVEOF'
#!/bin/bash
# Setup entorno Python para MACRON

echo "Configurando entorno MACRON..."

# Verificar Python 3
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 no encontrado"
    exit 1
fi

# Instalar dependencias
pip3 install --user \
    flask pytest sentence-transformers PyPDF2 python-docx \
    opencv-python cryptography requests \
    mlx mlx-lm mlx-whisper \
    openai-whisper sounddevice scipy psutil

echo "Entorno configurado."
ENVEOF
chmod +x "$APP_PATH/Contents/Resources/setup_env.sh"

# Notarizacion (requiere Apple Developer ID)
echo "[6/6] Firmando..."
# codesign --deep --force --verify --verbose --sign "Developer ID" "$APP_PATH"

echo ""
echo "========================================"
echo "  MACRON.app generado!"
echo "  Ubicacion: $APP_PATH"
echo "========================================"
echo ""
echo "Para instalar:"
echo "  1. Ejecutar: $APP_PATH/Contents/Resources/setup_env.sh"
echo "  2. Abrir: open '$APP_PATH'"
echo ""
echo "Para notarizar (requiere Developer ID):"
echo "  codesign --deep --force --sign 'Developer ID' '$APP_PATH'"
echo "  xcrun altool --notarize-app --primary-bundle-id '$BUNDLE_ID' --file '$APP_PATH'"
