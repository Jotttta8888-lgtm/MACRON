#!/bin/bash
# MACRON Launcher v6.6.2
# Ejecutar desde Terminal: ./start_macron.sh

cd ~/Documents/MACRON
source venv/bin/activate

# Matar servidor anterior si existe
lsof -ti:5001 | xargs kill -9 2>/dev/null

echo "Iniciando MACRON v6.6.2..."
echo "Abriendo Safari en 8 segundos..."

# Iniciar servidor en background
python3 macron_ui_v3.py &
SERVER_PID=$!

# Esperar a que cargue
sleep 8

# Abrir Safari
open "http://127.0.0.1:5001"

# Mostrar notificación
osascript -e 'display notification "MACRON v6.6.2 listo en http://127.0.0.1:5001" with title "MACRON AI"'

echo ""
echo "Servidor corriendo en PID: $SERVER_PID"
echo "Presiona CTRL+C para detener"
wait $SERVER_PID
