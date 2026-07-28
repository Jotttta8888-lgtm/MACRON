#!/bin/bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
PASS=0; FAIL=0; WARN=0
log_pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; ((PASS++)); }
log_fail() { echo -e "${RED}❌ FAIL${NC}: $1"; ((FAIL++)); }
log_warn() { echo -e "${YELLOW}⚠️ WARN${NC}: $1"; ((WARN++)); }
log_info() { echo -e "${BLUE}ℹ️ INFO${NC}: $1"; }

SRC="/Users/juancamilo/Documents/MACRON/MACRON_v4/Sources/MACRON"

echo "═══════════════════════════════════════════════════"
echo "  🧠 MACRON v4.6.1 — Testing Suite v2 — Mac NEO"
echo "═══════════════════════════════════════════════════"

# 1. BUILD
echo ""; echo "📦 [1/10] Build Verification"
cd ~/Documents/MACRON/MACRON_v4
swift build -c release 2>&1 | grep -q "Build complete" && log_pass "Build release (0 errores)" || log_fail "Build fallido"

# 2. APP BUNDLE
echo ""; echo "📦 [2/10] App Bundle"
[ -f ".build/release/MACRON.app/Contents/MacOS/MACRON" ] && log_pass "Binary: $(ls -lh .build/release/MACRON.app/Contents/MacOS/MACRON | awk '{print $5}')" || log_fail "Binary no encontrado"
[ -f ".build/release/MACRON.app/Contents/Info.plist" ] && log_pass "Info.plist OK" || log_fail "Info.plist ausente"

# 3. DMG
echo ""; echo "📦 [3/10] DMG Release"
[ -f ".build/release/MACRON_v4.6.1_150features.dmg" ] && log_pass "DMG: $(ls -lh .build/release/MACRON_v4.6.1_150features.dmg | awk '{print $5}')" || log_warn "DMG no encontrado"

# 4. GIT
echo ""; echo "📦 [4/10] Git Repo"
cd ~/Documents/MACRON
git log --oneline -1 | grep -q "v4.6.1" && log_pass "Commit v4.6.1" || log_warn "Commit no encontrado"
git tag | grep -q "v4.6.1" && log_pass "Tag v4.6.1" || log_warn "Tag no encontrado"

# 5. FEATURES
echo ""; echo "📦 [5/10] Feature Count"
FEATURES=$(find $SRC -name "*.swift" | wc -l | tr -d ' ')
log_info "Archivos Swift: $FEATURES"
[ "$FEATURES" -ge 60 ] && log_pass "Base robusta ($FEATURES archivos)" || log_warn "Pocos archivos"

# 6. UI FILES
echo ""; echo "📦 [6/10] SwiftUI Interface"
for f in ContentView.swift DashboardView.swift ChatView.swift FeatureGridView.swift ToolsView.swift SettingsView.swift SidebarView.swift MACRONApp.swift; do
    [ -f "$SRC/$f" ] && log_pass "UI: $f" || log_fail "UI ausente: $f"
done

# 7. BRAIN
echo ""; echo "📦 [7/10] Brain Modules"
for f in VoiceContextEngine.swift RealtimeTranscriber.swift AgentOrchestrator.swift ReasoningEngine.swift VoiceBiometrics.swift ProactiveAI.swift MACRONBrain.swift; do
    [ -f "$SRC/$f" ] && log_pass "Brain: $f" || log_fail "Brain ausente: $f"
done

# 8. AI FEATURES
echo ""; echo "📦 [8/10] AI Features FF-FO"
for f in SmartHomeAI.swift ScreenReaderAI.swift CodeAssistant.swift SmartScheduler.swift DocumentAI.swift ScreenCaptureAI.swift EmailDraftAI.swift WindowManagerAI.swift ClipboardAI.swift QuickTranslate.swift; do
    [ -f "$SRC/$f" ] && log_pass "AI: $f" || log_fail "AI ausente: $f"
done

# 9. PERMISSIONS
echo ""; echo "📦 [9/10] Permissions"
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * FROM access WHERE client LIKE '%MACRON%'" 2>/dev/null | grep -q "MACRON" && log_pass "Accessibility OK" || log_warn "MACRON NO en Accessibility (configurar manualmente)"

# 10. RESUMEN
echo ""; echo "═══════════════════════════════════════════════════"
echo "  📊 RESUMEN"; echo "═══════════════════════════════════════════════════"
echo -e "${GREEN}✅ PASS: $PASS${NC}"; echo -e "${RED}❌ FAIL: $FAIL${NC}"; echo -e "${YELLOW}⚠️ WARN: $WARN${NC}"
[ $FAIL -eq 0 ] && echo -e "${GREEN}🎉 MACRON v4.6.1 LISTO — 0 errores${NC}" || echo -e "${RED}⚠️ Revisar $FAIL fallos${NC}"
