#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo "═══════════════════════════════════════════════════════"
echo "  🧪 MACRON v4.9.0 — Testing Manual — Mac NEO"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Instrucciones: Abre MACRON.app y sigue cada prueba."
echo "Marca [✓] si funciona, [✗] si falla."
echo ""

tests=(
    "1.  🎙️  Voz: Di 'Hey Macron, abre Safari' → Safari se abre"
    "2.  🧠 LLM: Di 'Hey Macron, que hora es' → Responde con hora actual"
    "3.  🏠 Focus: Di 'Modo focus' → Inicia sesion Pomodoro 25min"
    "4.  🔍 SmartSearch: Di 'Busca archivo reporte' → Muestra resultados"
    "5.  📊 Diagnostico: Di 'Diagnostico del sistema' → Muestra CPU/RAM"
    "6.  📧 Email: Di 'Resume mis emails' → Briefing de Mail.app"
    "7.  🏡 HomeKit: Di 'Modo noche' → Activa escena (si configuras Shortcuts)"
    "8.  💻 Debug: Abre Xcode, selecciona codigo con error, Di 'Explica este error'"
    "9.  🌍 Traduce: Copia texto en ingles, Di 'Traduce esto' → Espanol en clipboard"
    "10. 📁 Organiza: Di 'Organiza mi escritorio' → Archivos movidos a carpetas"
    "11. 📋 Clipboard: Copia varios textos, verifica historial en MACRON"
    "12. 🎤 VoiceClone: Settings > Seguridad > Grabar voz 30s"
    "13. 📝 Presentacion: Di 'Crea presentacion sobre IA' → Keynote se abre"
    "14. 📸 Screen: Abre web con precios, Di 'Que precios ves' → OCR + precios"
    "15. 📅 Calendar: Di 'Reunete con Maria manana a las 3' → Evento creado"
)

for t in "${tests[@]}"; do
    echo -e "${BLUE}$t${NC}"
    echo "   Resultado: ________________________________"
    echo ""
done

echo "═══════════════════════════════════════════════════════"
echo "  Cuando termines, copia este output y pegalo aqui."
echo "═══════════════════════════════════════════════════════"
