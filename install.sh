#!/bin/bash
# MACRON v4.0 - Instalador Automático
# Uso: cd ~/Documents/MACRON && bash install.sh

set -e

echo "=========================================="
echo "  MACRON v4.0 - Instalador"
echo "=========================================="

# 1. Verificar Python 3.11+
if ! python3 --version | grep -E "3\.(1[1-9]|[2-9][0-9])" > /dev/null; then
    echo "❌ Error: Se requiere Python 3.11+"
    exit 1
fi
echo "✅ Python OK"

# 2. Crear entorno virtual
if [ ! -d "venv" ]; then
    echo "📦 Creando entorno virtual..."
    python3 -m venv venv
fi
source venv/bin/activate

# 3. Instalar dependencias
echo "📦 Instalando dependencias..."
pip install -q flask flask-cors sentence-transformers 2>/dev/null || true

# 4. Copiar app a Aplicaciones
echo "📦 Instalando MACRON.app..."
rm -rf /Applications/MACRON.app
cp -R MACRON.app /Applications/
cp -R "MACRON Spotlight.app" /Applications/ 2>/dev/null
xattr -cr /Applications/MACRON.app 2>/dev/null || true

# 5. Configurar LaunchAgent
echo "📦 Configurando auto-inicio..."
mkdir -p ~/Library/LaunchAgents
cp com.macron.agent.plist ~/Library/LaunchAgents/ 2>/dev/null || true
launchctl load ~/Library/LaunchAgents/com.macron.agent.plist 2>/dev/null || true

# 6. Crear directorio de datos
mkdir -p ~/Documents/MACRON

# 7. Permisos
echo "🔧 Configurando permisos..."
chmod +x /Applications/MACRON.app/Contents/MacOS/MACRON
cp MACRON.app/Contents/Resources/AppIcon.icns /Applications/MACRON.app/Contents/Resources/ 2>/dev/null

echo ""
echo "=========================================="
echo "  ✅ MACRON v4.0 instalado!"
echo ""
echo "  • App: /Applications/MACRON.app"
echo "  • Backend: auto-inicio activado"
echo "  • Datos: ~/Documents/MACRON/"
echo ""
echo "  Primeros pasos:"
echo "  1. Abre MACRON desde Aplicaciones"
echo "  2. Otorga permisos de Accesibilidad"
echo "  3. Di 'Hey MACRON' o presiona Cmd+Shift+M"
echo "=========================================="
