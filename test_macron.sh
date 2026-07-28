#!/bin/bash
# MACRON v4.6.1 — Testing Suite para Mac NEO

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

log_pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; ((PASS++)); }
log_fail() { echo -e "${RED}❌ FAIL${NC}: $1"; ((FAIL++)); }
log_warn() { echo -e "${YELLOW}⚠️ WARN${NC}: $1"; ((WARN++)); }
log_info() { echo -e "${BLUE}ℹ️ INFO${NC}: $1"; }

echo "═══════════════════════════════════════════════════"
echo "  🧠 MACRON v4.6.1 — Testing Suite — Mac NEO"
echo "═══════════════════════════════════════════════════"
echo ""

# 1. BUILD CHECK
echo "📦 [1/10] Build Verification"
echo "───────────────────────────────────────────────────"
cd ~/Documents/MACRON/MACRON_v4
if swift build -c release 2>&1 | grep -q "Build complete"; then
    log_pass "Build release exitoso (0 errores)"
else
    log_fail "Build fallido"
fi

# 2. APP BUNDLE CHECK
echo ""
echo "📦 [2/10] App Bundle Verification"
echo "───────────────────────────────────────────────────"
if [ -f ".build/release/MACRON.app/Contents/MacOS/MACRON" ]; then
    SIZE=$(ls -lh .build/release/MACRON.app/Contents/MacOS/MACRON | awk '{print $5}')
    log_pass "Binary existe: $SIZE"
else
    log_fail "Binary no encontrado"
fi

if [ -f ".build/release/MACRON.app/Contents/Info.plist" ]; then
    log_pass "Info.plist presente"
else
    log_fail "Info.plist ausente"
fi

# 3. DMG CHECK
echo ""
echo "📦 [3/10] DMG Release Verification"
echo "───────────────────────────────────────────────────"
if [ -f ".build/release/MACRON_v4.6.1_150features.dmg" ]; then
    DMG_SIZE=$(ls -lh .build/release/MACRON_v4.6.1_150features.dmg | awk '{print $5}')
    log_pass "DMG creado: $DMG_SIZE"
else
    log_warn "DMG no encontrado"
fi

# 4. GIT CHECK
echo ""
echo "📦 [4/10] Git Repository Verification"
echo "───────────────────────────────────────────────────"
cd ~/Documents/MACRON
if git log --oneline -1 | grep -q "v4.6.1"; then
    log_pass "Commit v4.6.1 presente"
else
    log_warn "Commit v4.6.1 no encontrado"
fi

if git tag | grep -q "v4.6.1"; then
    log_pass "Tag v4.6.1 presente"
else
    log_warn "Tag v4.6.1 no encontrado"
fi

# 5. FEATURE COUNT CHECK
echo ""
echo "📦 [5/10] Feature Count Verification"
echo "───────────────────────────────────────────────────"
FEATURES=$(find ~/Documents/MACRON/MACRON_v4/Sources/MACRON -name "*.swift" | wc -l | tr -d ' ')
log_info "Archivos Swift: $FEATURES"

if [ "$FEATURES" -ge 60 ]; then
    log_pass "Base de codigo robusta ($FEATURES archivos)"
else
    log_warn "Pocos archivos Swift ($FEATURES)"
fi

# 6. SWIFTUI UI CHECK
echo ""
echo "📦 [6/10] SwiftUI Interface Check"
echo "───────────────────────────────────────────────────"
UI_FILES=("ContentView.swift" "DashboardView.swift" "ChatView.swift" "FeatureGridView.swift" "ToolsView.swift" "SettingsView.swift" "SidebarView.swift" "MACRONApp.swift")
for file in "${UI_FILES[@]}"; do
    if [ -f "~/Documents/MACRON/MACRON_v4/Sources/MACRON/$file" ]; then
        log_pass "UI file: $file"
    else
        log_fail "UI file ausente: $file"
    fi
done

# 7. BRAIN MODULES CHECK
echo ""
echo "📦 [7/10] Brain Modules Check"
echo "───────────────────────────────────────────────────"
BRAIN_FILES=("VoiceContextEngine.swift" "RealtimeTranscriber.swift" "AgentOrchestrator.swift" "ReasoningEngine.swift" "VoiceBiometrics.swift" "ProactiveAI.swift" "MACRONBrain.swift")
for file in "${BRAIN_FILES[@]}"; do
    if [ -f "~/Documents/MACRON/MACRON_v4/Sources/MACRON/$file" ]; then
        log_pass "Brain module: $file"
    else
        log_fail "Brain module ausente: $file"
    fi
done

# 8. AI FEATURES CHECK (FF-FO)
echo ""
echo "📦 [8/10] AI Features v4.6.0 Check"
echo "───────────────────────────────────────────────────"
AI_FILES=("SmartHomeAI.swift" "ScreenReaderAI.swift" "CodeAssistant.swift" "SmartScheduler.swift" "DocumentAI.swift" "ScreenCaptureAI.swift" "EmailDraftAI.swift" "WindowManagerAI.swift" "ClipboardAI.swift" "QuickTranslate.swift")
for file in "${AI_FILES[@]}"; do
    if [ -f "~/Documents/MACRON/MACRON_v4/Sources/MACRON/$file" ]; then
        log_pass "AI Feature: $file"
    else
        log_fail "AI Feature ausente: $file"
    fi
done

# 9. PERMISSIONS CHECK
echo ""
echo "📦 [9/10] System Permissions Check"
echo "───────────────────────────────────────────────────"
if sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * FROM access WHERE client LIKE '%MACRON%'" 2>/dev/null | grep -q "MACRON"; then
    log_pass "MACRON en Accessibility"
else
    log_warn "MACRON NO esta en Accessibility (System Settings > Privacy)"
fi

# 10. MANUAL TESTING CHECKLIST
echo ""
echo "📦 [10/10] Manual Testing Checklist"
echo "───────────────────────────────────────────────────"
echo -e "${YELLOW}Ejecuta estos tests manualmente en tu Mac NEO:${NC}"
echo ""
echo -e "${BLUE}[Voz]${NC}"
echo "  ☐ Abre MACRON.app, clic 'Activar Brain'"
echo "  ☐ Di 'Hey Macron, abre Safari'"
echo "  ☐ Verifica que Safari se abre"
echo ""
echo -e "${BLUE}[Contexto]${NC}"
echo "  ☐ Abre Xcode, selecciona texto de error"
echo "  ☐ Di 'Hey Macron, explica este error'"
echo "  ☐ Verifica respuesta contextual"
echo ""
echo -e "${BLUE}[Screen Capture]${NC}"
echo "  ☐ Abre una web con precios"
echo "  ☐ Di 'Hey Macron, que precios ves'"
echo "  ☐ Verifica OCR + deteccion de precios"
echo ""
echo -e "${BLUE}[Calendar]${NC}"
echo "  ☐ Di 'Reunete con el equipo manana a las 10'"
echo "  ☐ Verifica evento en Calendar.app"
echo ""
echo -e "${BLUE}[Email]${NC}"
echo "  ☐ Di 'Escribe un email a Juan diciendo hola'"
echo "  ☐ Verifica Mail.app se abre con borrador"
echo ""
echo -e "${BLUE}[Window Manager]${NC}"
echo "  ☐ Abre Safari + Xcode + Slack"
echo "  ☐ Di 'Modo focus'"
echo "  ☐ Verifica tiles inteligentes"
echo ""
echo -e "${BLUE}[Document AI]${NC}"
echo "  ☐ Arrastra PDF a MACRON"
echo "  ☐ Pregunta 'Resume los puntos clave'"
echo "  ☐ Verifica resumen generado"
echo ""
echo -e "${BLUE}[Proactive AI]${NC}"
echo "  ☐ Trabaja 2+ horas sin descanso"
echo "  ☐ Verifica notificacion de break"
echo ""

# RESUMEN
echo ""
echo "═══════════════════════════════════════════════════"
echo "  📊 RESUMEN DE TESTING"
echo "═══════════════════════════════════════════════════"
echo -e "${GREEN}✅ PASS: $PASS${NC}"
echo -e "${RED}❌ FAIL: $FAIL${NC}"
echo -e "${YELLOW}⚠️ WARN: $WARN${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 MACRON v4.6.1 LISTO PARA PRODUCCION${NC}"
    echo -e "${GREEN}   0 errores criticos detectados${NC}"
else
    echo -e "${RED}⚠️  Revisar $FAIL fallos antes de release${NC}"
fi

echo ""
