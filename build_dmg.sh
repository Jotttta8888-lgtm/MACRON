#!/bin/bash
set -e

APP_NAME="MACRON"
APP_PATH="/Applications/MACRON.app"
DMG_NAME="MACRON-v4.0.0.dmg"
VOL_NAME="MACRON Installer"
TMP_DMG="/tmp/macron_tmp.dmg"
FINAL_DMG="$HOME/Documents/MACRON/$DMG_NAME"

echo "=== Construyendo DMG para $APP_NAME ==="

# Verificar app
if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH no encontrada"
    exit 1
fi

# Crear imagen temporal
hdiutil create -srcfolder "$APP_PATH" -volname "$VOL_NAME" -fs HFS+ -format UDRW -size 2g "$TMP_DMG"

# Montar
MOUNT_POINT=$(hdiutil attach -readwrite -noverify "$TMP_DMG" | grep -o '/Volumes/.*')

# Fondo personalizado
mkdir -p "$MOUNT_POINT/.background"
cat > "$MOUNT_POINT/.background/background.svg" << 'SVG'
<svg width="600" height="400" xmlns="http://www.w3.org/2000/svg">
  <rect width="600" height="400" fill="#1a1a2e"/>
  <text x="300" y="180" font-family="Helvetica" font-size="32" fill="#fff" text-anchor="middle">MACRON v4.0.0</text>
  <text x="300" y="220" font-family="Helvetica" font-size="16" fill="#aaa" text-anchor="middle">Arrastra MACRON a Applications</text>
</svg>
SVG

# Alias de Applications
ln -s /Applications "$MOUNT_POINT/Applications"

# Ejectar
hdiutil detach "$MOUNT_POINT"

# Convertir a comprimido
hdiutil convert "$TMP_DMG" -format UDZO -o "$FINAL_DMG"
rm -f "$TMP_DMG"

echo "=== DMG creado: $FINAL_DMG ==="
