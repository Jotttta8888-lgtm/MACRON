from cryptography.fernet import Fernet
"""
MACRON UI v3.1 — Conectado a macron_core.py
Expone las 20+ funcionalidades via API REST
"""
import os, sys, json, time, threading
from concurrent.futures import ThreadPoolExecutor
from macron_voice_vad import MacronVoiceInterface
from macron_wake_whisper import MacronWakeWordWhisper
from macron_core import get_core
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, render_template_string, request, jsonify

app = Flask(__name__)

# Memoria de conversación persistente
_conversation_memory = []
_MAX_MEMORY = 20

def _add_to_memory(role, text, action=None):
    global _conversation_memory
    entry = {
        'timestamp': __import__('datetime').datetime.now().isoformat(),
        'role': role,
        'text': text,
        'action': action
    }
    _conversation_memory.append(entry)
    if len(_conversation_memory) > _MAX_MEMORY:
        _conversation_memory = _conversation_memory[-_MAX_MEMORY:]
    # Guardar a disco
    try:
        import json, os
        mem_file = os.path.expanduser('~/Documents/MACRON/conversation_memory.json')
        with open(mem_file, 'w') as f:
            json.dump(_conversation_memory, f, indent=2, ensure_ascii=False)
    except:
        pass

def _get_memory_context():
    global _conversation_memory
    if not _conversation_memory:
        try:
            import json, os
            mem_file = os.path.expanduser('~/Documents/MACRON/conversation_memory.json')
            if os.path.exists(mem_file):
                with open(mem_file, 'r') as f:
                    _conversation_memory = json.load(f)
        except:
            pass
    # Formatear últimos 5 mensajes como contexto
    recent = _conversation_memory[-5:]
    context = []
    for m in recent:
        prefix = "Usuario" if m['role'] == 'user' else "MACRON"
        context.append(f"{prefix}: {m['text']}")
    return "\n".join(context) if context else ""



# ── CORE UNIFICADO ─────────────────────────────────────────────
_core = None
_core_lock = threading.Lock()

def get_macron_core():
    global _core
    if _core is None:
        with _core_lock:
            if _core is None:
                _core = get_core()
    return _core

# Executor de UN SOLO thread para MLX
_llm_executor = ThreadPoolExecutor(max_workers=1)

# Voice interface (lazy loading)
_voice_interface = None
_voice_lock = threading.Lock()

def get_voice_interface():
    global _voice_interface
    if _voice_interface is None:
        with _voice_lock:
            if _voice_interface is None:
                _voice_interface = MacronVoiceInterface()
    return _voice_interface

# Wake word listener (lazy loading)
_wake_listener = None
_wake_lock = threading.Lock()

def get_wake_listener():
    global _wake_listener
    if _wake_listener is None:
        with _wake_lock:
            if _wake_listener is None:
                voice = get_voice_interface()
                core = get_macron_core()
                orchestrator = core.orchestrator if core and core.orchestrator else core
                _wake_listener = MacronWakeWordWhisper(voice, orchestrator)
    return _wake_listener

# ── ESTADO REAL DE MÓDULOS ────────────────────────────────────
def get_module_status_html():
    try:
        core = get_macron_core()
        status = core.get_status()
        modules = []
        for name in status.get('active', []):
            modules.append(f'<span class="chip on"><span class="status-dot on"></span>{name}</span>')
        for name in status.get('inactive', []):
            modules.append(f'<span class="chip off"><span class="status-dot off"></span>{name}</span>')
        return "\n".join(modules) if modules else '<span class="chip off">Cargando...</span>'
    except Exception as e:
        return f'<span class="chip off">Error: {e}</span>'

HTML = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MACRON v6.6</title>
<style>
:root { --accent: #00d4aa; --accent-dim: rgba(0,212,170,0.12); --bg: #0a0a0f; --surface: #12121a; --surface-raised: #1a1a2e; --border: #1a1a2e; --text: #e0e0e0; --text-secondary: #888; --text-muted: #555; --danger: #ff4757; --success: #00d4aa; --warning: #f59e0b; }
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, sans-serif; min-height: 100vh; display: flex; }
.sidebar { width: 300px; background: var(--surface); border-right: 1px solid var(--border); padding: 20px; display: flex; flex-direction: column; gap: 16px; overflow-y: auto; }
.sidebar h1 { font-size: 22px; font-weight: 600; color: var(--accent); letter-spacing: -0.5px; }
.version { font-size: 11px; color: var(--text-muted); margin-top: -12px; }
.hardware { display: flex; flex-direction: column; gap: 8px; }
.hw-item { display: flex; justify-content: space-between; font-size: 12px; padding: 7px 10px; background: var(--surface-raised); border-radius: 6px; }
.hw-label { color: var(--text-secondary); }
.hw-value { color: var(--accent); font-weight: 500; }
.modules-section h3 { font-size: 12px; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; }
.modules-grid { display: flex; flex-wrap: wrap; gap: 5px; }
.chip { font-size: 10px; padding: 3px 8px; border-radius: 5px; display: flex; align-items: center; gap: 4px; font-weight: 500; }
.chip.on { background: var(--accent-dim); color: var(--accent); }
.chip.off { background: rgba(85,85,85,0.15); color: var(--text-muted); }
.status-dot { width: 5px; height: 5px; border-radius: 50%; display: inline-block; }
.status-dot.on { background: var(--success); box-shadow: 0 0 4px var(--success); }
.status-dot.off { background: var(--text-muted); }
.quick-actions { display: flex; flex-direction: column; gap: 6px; }
.qa-btn { padding: 8px 12px; border: 1px solid var(--border); background: var(--surface-raised); color: var(--text-secondary); border-radius: 6px; font-size: 12px; cursor: pointer; text-align: left; transition: all 0.2s; }
.qa-btn:hover { border-color: var(--accent); color: var(--accent); }
.qa-btn.active { background: var(--accent-dim); color: var(--accent); border-color: var(--accent); }
.main { flex: 1; display: flex; flex-direction: column; height: 100vh; }
.chat-header { padding: 16px 20px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
.chat-header h2 { font-size: 15px; font-weight: 500; }
.status-badge { font-size: 11px; padding: 4px 10px; border-radius: 20px; background: var(--accent-dim); color: var(--accent); display: flex; align-items: center; gap: 6px; }
.status-badge.warning { background: rgba(245,158,11,0.15); color: var(--warning); }
.chat-messages { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 14px; }
.message { display: flex; gap: 10px; max-width: 80%; animation: fadeIn 0.3s ease; }
.message.user { align-self: flex-end; flex-direction: row-reverse; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
.avatar { width: 30px; height: 30px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; flex-shrink: 0; }
.message.assistant .avatar { background: var(--accent-dim); color: var(--accent); }
.message.user .avatar { background: var(--surface-raised); color: var(--text); }
.bubble { padding: 10px 14px; border-radius: 12px; font-size: 13px; line-height: 1.5; word-wrap: break-word; }
.message.assistant .bubble { background: var(--surface-raised); border: 1px solid var(--border); border-top-left-radius: 4px; }
.message.user .bubble { background: var(--accent); color: var(--bg); border-top-right-radius: 4px; }
.typing { display: flex; gap: 4px; padding: 10px 14px; }
.typing-dot { width: 5px; height: 5px; background: var(--text-secondary); border-radius: 50%; animation: typing 1.4s infinite; }
.typing-dot:nth-child(2) { animation-delay: 0.2s; }
.typing-dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes typing { 0%, 60%, 100% { transform: translateY(0); } 30% { transform: translateY(-4px); } }
.chat-input { padding: 14px 20px; border-top: 1px solid var(--border); display: flex; gap: 8px; align-items: center; }
.chat-input input { flex: 1; padding: 10px 14px; border: 1px solid var(--border); border-radius: 8px; background: var(--surface); color: var(--text); font-size: 13px; outline: none; }
.chat-input input:focus { border-color: var(--accent); }
.chat-input input::placeholder { color: var(--text-muted); }
.chat-input button { padding: 10px 18px; border: none; border-radius: 8px; background: var(--accent); color: var(--bg); font-size: 13px; font-weight: 600; cursor: pointer; }
.chat-input button:disabled { opacity: 0.5; cursor: not-allowed; }
.voice-btn, .wake-btn { width: 36px; height: 36px; border-radius: 8px; border: 1px solid var(--border); background: var(--surface); color: var(--text-secondary); cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 14px; }
.voice-btn.recording { background: var(--danger); color: white; border-color: var(--danger); animation: pulse 1.5s infinite; }
.wake-btn.listening { background: var(--accent); color: white; border-color: var(--accent); animation: pulse 1.5s infinite; }
@keyframes pulse { 0%, 100% { box-shadow: 0 0 0 0 rgba(255,71,87,0.4); } 50% { box-shadow: 0 0 0 8px rgba(255,71,87,0); } }
.clear-btn { font-size: 11px; color: var(--text-muted); background: none; border: 1px solid var(--border); padding: 5px 10px; border-radius: 6px; cursor: pointer; }
.empty-state { text-align: center; padding: 50px 20px; color: var(--text-muted); }
.empty-state h3 { font-size: 16px; color: var(--text-secondary); margin-bottom: 6px; }
.focus-overlay { display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.85); z-index: 1000; flex-direction: column; align-items: center; justify-content: center; color: white; }
.focus-overlay.active { display: flex; }
.focus-timer { font-size: 72px; font-weight: 200; font-variant-numeric: tabular-nums; }
.focus-label { font-size: 14px; color: var(--text-secondary); margin-top: 10px; }
.focus-stop { margin-top: 30px; padding: 10px 24px; background: var(--danger); color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 14px; }
@media (max-width: 768px) { .sidebar { display: none; } }
</style>
</head>
<body>
<div class="sidebar">
    <div><h1>MACRON</h1><div class="version" id="versionText">v6.6.1 &middot; Core Conectado</div></div>
    <div class="hardware">
        <div class="hw-item"><span class="hw-label">Apple Silicon</span><span class="hw-value">M1/M2</span></div>
        <div class="hw-item"><span class="hw-label">MLX</span><span class="hw-value">GPU ON</span></div>
        <div class="hw-item"><span class="hw-label">MPS</span><span class="hw-value">Activado</span></div>
        <div class="hw-item"><span class="hw-label">RAM</span><span class="hw-value">8 GB</span></div>
        <div class="hw-item"><span class="hw-label">Modelo</span><span class="hw-value">1.5B 4bit</span></div>
        <div class="hw-item"><span class="hw-label">Modulos</span><span class="hw-value" id="moduleCount">Cargando...</span></div>
    </div>
    <div class="modules-section"><h3>Modulos Activos</h3><div class="modules-grid" id="modulesGrid">{{ modules_html | safe }}</div></div>
    <div class="quick-actions">
        <h3 style="font-size:12px;color:var(--text-secondary);text-transform:uppercase;letter-spacing:0.5px;">Acciones Rapidas</h3>
        <button class="qa-btn" onclick="toggleFocus()">&#127813; Modo Focus (Pomodoro)</button>
        <button class="qa-btn" onclick="showHistory()">&#128220; Historial</button>
        <button class="qa-btn" onclick="exportChat()">&#128228; Exportar Chat</button>
        <button class="qa-btn" onclick="clearChat()">&#128465; Limpiar Chat</button>
        <button class="qa-btn" onclick="refreshStatus()">&#128260; Actualizar Estado</button>
        <button class="qa-btn" onclick="showSafariTabs()">&#128279; Safari Tabs</button>
        <button class="qa-btn" onclick="summarizePage()">&#128240; Resumir Pagina</button>
        <button class="qa-btn" onclick="saveForLater()">&#128278; Guardar para leer</button>
        <button class="qa-btn" onclick="showMailInbox()">&#128231; Mail Inbox</button>
        <button class="qa-btn" onclick="summarizeMail()">&#128240; Resumir Mail</button>
        <button class="qa-btn" onclick="showFinderDesktop()">&#128193; Desktop</button>
        <button class="qa-btn" onclick="showFinderDownloads()">&#128229; Downloads</button>
        <button class="qa-btn" onclick="showFinderRecent()">&#128338; Recientes</button>
        <button class="qa-btn" onclick="showCalendarToday()">&#128197; Hoy</button>
        <button class="qa-btn" onclick="showCalendarUpcoming()">&#128467; Proximos</button>
        <button class="qa-btn" onclick="showNotesList()">&#128221; Notas</button>
        <button class="qa-btn" onclick="showNotesSearch()">&#128270; Buscar Notas</button>
        <button class="qa-btn" onclick="showRemindersPending()">&#9989; Pendientes</button>
        <button class="qa-btn" onclick="showRemindersCreate()">&#10133; Nuevo Recordatorio</button>
        <button class="qa-btn" onclick="showAgentSummary()">&#129302; Resumen Diario</button>
        <button class="qa-btn" onclick="showMonitorReport()">&#128065; Monitoreo</button>
    </div>
</div>
<div class="main">
    <div class="chat-header">
        <h2>Chat con MACRON</h2>
        <div style="display:flex;gap:10px;align-items:center;">
            <span class="status-badge" id="statusBadge"><span class="status-dot on"></span>En linea</span>
            <button class="clear-btn" onclick="clearChat()">Limpiar</button>
        </div>
    </div>
    <div class="chat-messages" id="chatMessages">
        <div class="empty-state" id="emptyState">
            <h3>Bienvenido a MACRON v6.6</h3>
            <p>Escribe un mensaje o usa el microfono. Todos los modulos estan conectados.</p>
        </div>
    </div>
    <div class="chat-input">
        <button class="voice-btn" id="voiceBtn" onclick="toggleVoice()" title="Grabar voz">&#127908;</button>
        <button class="wake-btn" id="wakeBtn" onclick="toggleWakeWord()" title="Escucha continua">&#128266;</button>
        <input type="text" id="messageInput" placeholder="Escribe tu mensaje..." onkeypress="if(event.key==='Enter')sendMessage()">
        <button id="sendBtn" onclick="sendMessage()">Enviar</button>
    </div>
</div>
<div class="focus-overlay" id="focusOverlay">
    <div class="focus-timer" id="focusTimer">25:00</div>
    <div class="focus-label">Modo Focus activo - Sin distracciones</div>
    <button class="focus-stop" onclick="toggleFocus()">Detener Focus</button>
</div>
<script>
let sessionId = 'session_' + Date.now();
let isRecording = false;
let messageHistory = [];
let focusInterval = null;

function addMessage(text, isUser, isError=false) {
    const container = document.getElementById('chatMessages');
    const empty = document.getElementById('emptyState');
    if (empty) empty.remove();
    const msgDiv = document.createElement('div');
    msgDiv.className = 'message ' + (isUser ? 'user' : 'assistant');
    const avatar = document.createElement('div');
    avatar.className = 'avatar';
    avatar.textContent = isUser ? 'TU' : 'M';
    const bubble = document.createElement('div');
    bubble.className = 'bubble';
    if (isError) { bubble.style.color = '#ff4757'; bubble.style.border = '1px solid #ff4757'; }
    bubble.textContent = text;
    msgDiv.appendChild(avatar);
    msgDiv.appendChild(bubble);
    container.appendChild(msgDiv);
    container.scrollTop = container.scrollHeight;
}

function showTyping() {
    const container = document.getElementById('chatMessages');
    const typing = document.createElement('div');
    typing.className = 'message assistant';
    typing.id = 'typingIndicator';
    typing.innerHTML = '<div class="avatar">M</div><div class="bubble typing"><div class="typing-dot"></div><div class="typing-dot"></div><div class="typing-dot"></div></div>';
    container.appendChild(typing);
    container.scrollTop = container.scrollHeight;
}

function hideTyping() {
    const typing = document.getElementById('typingIndicator');
    if (typing) typing.remove();
}

async function sendMessage() {
    const input = document.getElementById('messageInput');
    const btn = document.getElementById('sendBtn');
    const text = input.value.trim();
    if (!text) return;
    input.value = '';
    input.disabled = true;
    btn.disabled = true;
    addMessage(text, true);
    messageHistory.push({role: 'user', content: text});
    showTyping();
    try {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({message: text, session_id: sessionId, history: messageHistory})
        });
        const data = await response.json();
        hideTyping();
        console.log('[DEBUG] Server response:', data);
        if (data.error) {
            addMessage('[Error] ' + data.error, false, true);
        } else {
            const reply = data.text || data.response || data.content || data.output || 'Sin respuesta';
            addMessage(reply, false);
            messageHistory.push({role: 'assistant', content: reply});
        }
        if (messageHistory.length > 20) messageHistory = messageHistory.slice(-20);
    } catch (err) {
        hideTyping();
        addMessage('Error de conexion: ' + err.message, false, true);
        console.error('[DEBUG] Fetch error:', err);
    }
    input.disabled = false;
    btn.disabled = false;
    input.focus();
}

function clearChat() {
    document.getElementById('chatMessages').innerHTML = '<div class="empty-state" id="emptyState"><h3>Bienvenido a MACRON v6.6</h3><p>Escribe un mensaje o usa el microfono. Todos los modulos estan conectados.</p></div>';
    messageHistory = [];
}

async function toggleWakeWord() {
    const btn = document.getElementById("wakeBtn");
    try {
        const response = await fetch("/api/wake/toggle", {method: "POST"});
        const data = await response.json();
        console.log("[DEBUG] Wake:", data);
        if (data.listening) {
            btn.classList.add("listening");
            btn.title = "Escuchando...";
        } else {
            btn.classList.remove("listening");
            btn.title = "Escucha continua";
        }
    } catch (e) {
        console.error("[DEBUG] Wake error:", e);
    }
}

async function toggleVoice() {
    const btn = document.getElementById('voiceBtn');
    const input = document.getElementById('messageInput');
    btn.disabled = true;
    btn.classList.add('recording');
    btn.title = 'Grabando...';
    try {
        const response = await fetch('/api/voice/transcribe', {method: 'POST'});
        const data = await response.json();
        console.log('[DEBUG] Voice:', data);
        if (data.text && data.text.trim()) {
            input.value = data.text;
            sendMessage();
        }
    } catch (e) {
        console.error('[DEBUG] Voice error:', e);
    } finally {
        btn.disabled = false;
        btn.classList.remove('recording');
        btn.title = 'Grabar voz';
    }
}

async function toggleFocus() {
    try {
        const response = await fetch('/api/focus/toggle', {method: 'POST'});
        const data = await response.json();
        console.log('[DEBUG] Focus:', data);
        const overlay = document.getElementById('focusOverlay');
        const timer = document.getElementById('focusTimer');
        if (data.active) {
            overlay.classList.add('active');
            let remaining = data.remaining_minutes * 60;
            timer.textContent = Math.floor(remaining/60) + ':' + String(remaining%60).padStart(2,'0');
            focusInterval = setInterval(() => {
                remaining--;
                if (remaining <= 0) { clearInterval(focusInterval); overlay.classList.remove('active'); }
                else { timer.textContent = Math.floor(remaining/60) + ':' + String(remaining%60).padStart(2,'0'); }
            }, 1000);
        } else {
            overlay.classList.remove('active');
            if (focusInterval) clearInterval(focusInterval);
        }
    } catch (e) {
        console.error('[DEBUG] Focus error:', e);
    }
}

async function showHistory() {
    try {
        const response = await fetch('/api/history');
        const data = await response.json();
        console.log('[DEBUG] History:', data);
        let text = 'Historial de conversaciones:\n\n';
        if (data.conversations && data.conversations.length) {
            data.conversations.forEach((c, i) => { text += (i+1) + '. ' + c + '\n'; });
        } else { text += 'No hay conversaciones guardadas.'; }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] History error:', e);
    }
}

async function exportChat() {
    try {
        const response = await fetch('/api/export', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({format: 'json', session_id: sessionId})
        });
        const data = await response.json();
        console.log('[DEBUG] Export:', data);
        if (data.success) {
            addMessage('Chat exportado correctamente.', false);
        } else {
            addMessage('Export: ' + (data.error || 'Error desconocido'), false, true);
        }
    } catch (e) {
        console.error('[DEBUG] Export error:', e);
    }
}

async function refreshStatus() {
    try {
        const response = await fetch('/api/status');
        const data = await response.json();
        console.log('[DEBUG] Status:', data);
        document.getElementById('moduleCount').textContent = (data.modules_active || 0) + '/' + (data.modules_total || 0);
        const badge = document.getElementById('statusBadge');
        if (data.healthy) {
            badge.innerHTML = '<span class="status-dot on"></span>En linea';
            badge.className = 'status-badge';
        } else {
            badge.innerHTML = '<span class="status-dot off"></span>Degradado';
            badge.className = 'status-badge warning';
        }
    } catch (e) {
        console.error('[DEBUG] Status error:', e);
    }
}

async function showSafariTabs() {
    try {
        const response = await fetch('/api/safari/tabs');
        const data = await response.json();
        console.log('[DEBUG] Safari tabs:', data);
        let text = '🌐 Safari - ' + data.count + ' pestanas:\n\n';
        if (data.active) {
            text += '👉 ACTIVA: ' + data.active.title + '\n' + data.active.url + '\n\n';
        }
        if (data.tabs && data.tabs.length) {
            data.tabs.slice(0, 10).forEach((t, i) => {
                text += (i + 1) + '. ' + t.title + '\n   ' + t.url + '\n';
            });
            if (data.tabs.length > 10) text += '\n... y ' + (data.tabs.length - 10) + ' mas';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Safari error:', e);
        addMessage('Error accediendo a Safari', false, true);
    }
}

async function summarizePage() {
    try {
        addMessage('🤖 Analizando pagina activa...', false);
        const response = await fetch('/api/safari/summarize');
        const data = await response.json();
        console.log('[DEBUG] Summary:', data);
        if (data.error) {
            addMessage('Error: ' + data.error, false, true);
        } else {
            let text = '📝 Resumen de: ' + (data.title || 'Pagina actual') + '\n';
            text += '🔗 ' + (data.url || '') + '\n\n';
            text += data.summary;
            addMessage(text, false);
        }
    } catch (e) {
        console.error('[DEBUG] Summarize error:', e);
    }
}

async function saveForLater() {
    try {
        const response = await fetch('/api/safari/save', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({notes: 'Guardado desde MACRON UI'})
        });
        const data = await response.json();
        console.log('[DEBUG] Save:', data);
        if (data.success) {
            addMessage('✅ Pagina guardada para leer despues. Total: ' + data.total_saved, false);
        } else {
            addMessage('⚠️ ' + (data.error || 'No se pudo guardar'), false, true);
        }
    } catch (e) {
        console.error('[DEBUG] Save error:', e);
    }
}

async function showMailInbox() {
    try {
        const response = await fetch('/api/mail/inbox?limit=5');
        const data = await response.json();
        console.log('[DEBUG] Mail inbox:', data);
        let text = '📧 Mail - ' + data.count + ' emails:\n\n';
        if (data.emails && data.emails.length) {
            data.emails.forEach((e, i) => {
                const status = e.read ? '✅' : '🔴';
                text += status + ' ' + e.subject + '\n';
                text += '   De: ' + e.sender + '\n\n';
            });
        } else {
            text += 'No hay emails.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Mail error:', e);
        addMessage('Error accediendo a Mail', false, true);
    }
}

async function summarizeMail() {
    try {
        addMessage('🤖 Analizando emails no leidos...', false);
        const response = await fetch('/api/mail/summarize');
        const data = await response.json();
        console.log('[DEBUG] Mail summary:', data);
        if (data.error) {
            addMessage('Error: ' + data.error, false, true);
        } else {
            let text = '📧 Resumen de Mail (' + data.count + ' no leidos):\n\n';
            text += data.summary;
            addMessage(text, false);
        }
    } catch (e) {
        console.error('[DEBUG] Mail summarize error:', e);
    }
}

async function showFinderDesktop() {
    try {
        const response = await fetch('/api/finder/desktop');
        const data = await response.json();
        console.log('[DEBUG] Desktop:', data);
        let text = '📁 Desktop (' + data.count + ' archivos):\n\n';
        if (data.files && data.files.length) {
            data.files.slice(0, 10).forEach(f => {
                const icon = f.is_dir ? '📂' : '📄';
                text += icon + ' ' + f.name + '\n';
            });
            if (data.files.length > 10) text += '\n... y ' + (data.files.length - 10) + ' mas';
        } else {
            text += 'Desktop vacio.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Finder error:', e);
        addMessage('Error accediendo a Desktop', false, true);
    }
}

async function showFinderDownloads() {
    try {
        const response = await fetch('/api/finder/downloads');
        const data = await response.json();
        console.log('[DEBUG] Downloads:', data);
        let text = '📥 Downloads (' + data.count + ' archivos):\n\n';
        if (data.files && data.files.length) {
            data.files.slice(0, 10).forEach(f => {
                const icon = f.is_dir ? '📂' : '📄';
                text += icon + ' ' + f.name + '\n';
            });
            if (data.files.length > 10) text += '\n... y ' + (data.files.length - 10) + ' mas';
        } else {
            text += 'Downloads vacio.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Finder error:', e);
        addMessage('Error accediendo a Downloads', false, true);
    }
}

async function showFinderRecent() {
    try {
        const response = await fetch('/api/finder/recent?limit=10');
        const data = await response.json();
        console.log('[DEBUG] Recent:', data);
        let text = '🕐 Archivos recientes (' + data.count + '):\n\n';
        if (data.files && data.files.length) {
            data.files.forEach(f => {
                text += '📄 ' + f.name + '\n';
            });
        } else {
            text += 'No hay archivos recientes.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Finder error:', e);
        addMessage('Error accediendo a recientes', false, true);
    }
}


async function showCalendarToday() {
    try {
        const response = await fetch('/api/calendar/today');
        const data = await response.json();
        console.log('[DEBUG] Calendar today:', data);
        let text = '📅 Eventos de hoy (' + data.count + '):\n\n';
        if (data.events && data.events.length) {
            data.events.forEach(e => {
                text += '• ' + e.title + '\n';
                text += '  ' + e.start + '\n\n';
            });
        } else {
            text += 'No hay eventos hoy.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Calendar error:', e);
        addMessage('Error accediendo al calendario', false, true);
    }
}

async function showCalendarUpcoming() {
    try {
        const response = await fetch('/api/calendar/upcoming?days=7');
        const data = await response.json();
        console.log('[DEBUG] Calendar upcoming:', data);
        let text = '📅 Proximos eventos (' + data.count + ' en ' + data.days + ' dias):\n\n';
        if (data.events && data.events.length) {
            data.events.forEach(e => {
                text += '• ' + e.title + '\n';
                text += '  ' + e.start + '\n\n';
            });
        } else {
            text += 'No hay eventos proximos.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Calendar error:', e);
        addMessage('Error accediendo al calendario', false, true);
    }
}

async function showNotesList() {
    try {
        const response = await fetch('/api/notes/list');
        const data = await response.json();
        console.log('[DEBUG] Notes:', data);
        let text = '📝 Notas (' + data.count + '):\n\n';
        if (data.notes && data.notes.length) {
            data.notes.forEach((n, i) => {
                text += (i + 1) + '. ' + n.title + '\n';
            });
        } else {
            text += 'No hay notas.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Notes error:', e);
        addMessage('Error accediendo a Notas', false, true);
    }
}

async function showNotesSearch() {
    const query = prompt('Buscar en notas:');
    if (!query) return;
    try {
        const response = await fetch('/api/notes/search', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({query: query})
        });
        const data = await response.json();
        console.log('[DEBUG] Notes search:', data);
        let text = '🔍 Resultados para "' + query + '" (' + data.count + '):\n\n';
        if (data.notes && data.notes.length) {
            data.notes.forEach((n, i) => {
                text += (i + 1) + '. ' + n.title + '\n';
            });
        } else {
            text += 'No se encontraron notas.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Notes search error:', e);
        addMessage('Error buscando notas', false, true);
    }
}

async function showRemindersPending() {
    try {
        const response = await fetch('/api/reminders/pending');
        const data = await response.json();
        console.log('[DEBUG] Reminders:', data);
        let text = '✅ Recordatorios pendientes (' + data.count + '):\n\n';
        if (data.reminders && data.reminders.length) {
            data.reminders.forEach(r => {
                text += '• ' + r.title + '\n';
                text += '  Prioridad: ' + r.priority + '\n\n';
            });
        } else {
            text += 'No hay recordatorios pendientes.';
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Reminders error:', e);
        addMessage('Error accediendo a Recordatorios', false, true);
    }
}

async function showRemindersCreate() {
    const title = prompt('Titulo del recordatorio:');
    if (!title) return;
    try {
        const response = await fetch('/api/reminders/create', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({title: title})
        });
        const data = await response.json();
        console.log('[DEBUG] Reminder created:', data);
        if (data.success) {
            addMessage('✅ ' + data.message, false);
        } else {
            addMessage('⚠️ No se pudo crear el recordatorio', false, true);
        }
    } catch (e) {
        console.error('[DEBUG] Reminder create error:', e);
        addMessage('Error creando recordatorio', false, true);
    }
}

async function showAgentSummary() {
    try {
        addMessage('🤖 Generando resumen diario...', false);
        const response = await fetch('/api/agent/summary');
        const data = await response.json();
        console.log('[DEBUG] Agent summary:', data);
        if (data.error) {
            addMessage('Error: ' + data.error, false, true);
        } else {
            let text = '📊 Resumen del Agente:\n\n';
            text += data.summary || 'No hay datos suficientes.';
            addMessage(text, false);
        }
    } catch (e) {
        console.error('[DEBUG] Agent summary error:', e);
        addMessage('Error generando resumen', false, true);
    }
}

async function showMonitorReport() {
    try {
        const response = await fetch('/api/monitor/report');
        const data = await response.json();
        console.log('[DEBUG] Monitor:', data);
        let text = '👁 Monitoreo del Sistema:\n\n';
        if (data.error) {
            text += 'Error: ' + data.error;
        } else {
            text += JSON.stringify(data, null, 2);
        }
        addMessage(text, false);
    } catch (e) {
        console.error('[DEBUG] Monitor error:', e);
        addMessage('Error obteniendo reporte', false, true);
    }
}


refreshStatus();
document.getElementById('messageInput').focus();
</script>
</body>
</html>
"""

@app.route('/')
def home():
    modules_html = get_module_status_html()
    return render_template_string(HTML, modules_html=modules_html)

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.get_json()
    message = data.get('message', '')
    print(f"[SERVER] Received: {message[:50]}")
    try:
        core = get_macron_core()
        if core.orchestrator and hasattr(core.orchestrator, 'llm') and hasattr(core.orchestrator.llm, 'chat'):
            result = core.orchestrator.llm.chat(message)
        else:
            result = core.chat(message)

        print(f"[SERVER] type={type(result).__name__}, val={repr(result)[:150]}")

        text = ""
        if isinstance(result, dict):
            text = result.get('text', '') or result.get('response', '') or str(result)
        elif isinstance(result, str):
            text = result
        else:
            text = str(result)

        print(f"[SERVER] text={text[:100]}")
        return jsonify({'text': text})
    except Exception as e:
        import traceback
        print(f"[SERVER] ERROR: {e}")
        traceback.print_exc()
        return jsonify({'error': str(e), 'text': 'Error interno del servidor'}), 500

@app.route('/api/voice/transcribe', methods=['POST'])
def voice_transcribe():
    try:
        print('[SERVER] Iniciando grabacion VAD...')
        voice = get_voice_interface()
        text = voice.listen()
        print(f'[SERVER] Transcripcion: {repr(text)}')
        return jsonify({'text': text, 'status': 'done'})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e), 'text': ''}), 500

@app.route('/api/wake/toggle', methods=['POST'])
def wake_toggle():
    try:
        wake = get_wake_listener()
        if wake.is_listening:
            wake.stop_listening()
            return jsonify({'status': 'stopped', 'listening': False})
        else:
            wake.start_listening()
            return jsonify({'status': 'started', 'listening': True})
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@app.route('/api/status')
def status():
    try:
        core = get_macron_core()
        health = core.get_health()
        return jsonify({
            **health,
            'hardware': {
                'apple_silicon': True, 'mlx': True, 'mps': True,
                'ram_gb': 8.0, 'model': 'Llama-3.2-1B-Instruct-4bit'
            }
        })
    except Exception as e:
        return jsonify({'error': str(e), 'healthy': False}), 500




def _convert_result_to_strings(result):
    """Convierte cualquier resultado a dict de strings para JSON compatible"""
    if result is None:
        return {}
    if isinstance(result, dict):
        out = {}
        for k, v in result.items():
            if v is None:
                out[k] = ""
            elif isinstance(v, bool):
                out[k] = "true" if v else "false"
            elif isinstance(v, (dict, list)):
                import json
                out[k] = json.dumps(v)
            else:
                out[k] = str(v)
        return out
    return {"text": str(result)}


def _route_voice_action(text_lower):
    """Router expandido: detecta cientos de palabras clave"""
    keywords = {
        'focus_toggle': [
            'concentrarme', 'enfocarme', 'distracción', 'distracto', 'focus mode',
            'modo focus', 'modo concentración', 'no me concentro', 'pomodoro',
            'silenciar notificaciones', 'modo silencio', 'trabajar', 'estudiar',
            'modo trabajo', 'modo estudio', 'concentración', 'enfoque'
        ],
        'focus_status': [
            'estado focus', 'estado de focus', 'focus activo', 'focus encendido',
            'estoy en focus', 'modo focus activo'
        ],
        'safari_search': [
            'buscar en safari', 'navegar a', 'abrir safari', 'ir a', 'buscar sobre',
            'google', 'wikipedia', 'buscar en internet', 'investigar sobre',
            'buscar en google', 'buscar en la web', 'navegar a la página'
        ],
        'safari_get_tabs': [
            'tabs abiertas', 'pestañas abiertas', 'páginas abiertas', 'qué tengo abierto',
            'ventanas abiertas', 'qué tengo en safari'
        ],
        'safari_summarize': [
            'resumir página', 'resumen de la página', 'de qué trata esta página',
            'qué dice esta página', 'resumen del sitio'
        ],
        'mail_get_inbox': [
            'ver emails', 'ver correos', 'inbox', 'bandeja de entrada', 'mails',
            'mensajes de correo', 'emails nuevos', 'correos nuevos',
            'abrir mail', 'abrir correo', 'ver mi mail'
        ],
        'mail_get_unread_count': [
            'emails no leídos', 'correos no leídos', 'cuántos emails', 'notificaciones mail',
            'cuántos correos tengo', 'emails sin leer'
        ],
        'mail_search': [
            'buscar en mail', 'buscar correo', 'buscar email de', 'encontrar email',
            'buscar en correos'
        ],
        'calendar_today': [
            'eventos de hoy', 'qué tengo hoy', 'agenda de hoy', 'calendario hoy',
            'reuniones de hoy', 'citas de hoy', 'qué hay hoy', 'mi día hoy'
        ],
        'calendar_upcoming': [
            'próximos eventos', 'eventos próximos', 'qué viene', 'calendario próximo',
            'reuniones próximas', 'agenda próxima', 'qué hay mañana', 'esta semana'
        ],
        'calendar_add_event': [
            'agregar evento', 'nueva reunión', 'nueva cita', 'crear evento',
            'programar reunión', 'programar cita', 'añadir al calendario',
            'nuevo evento', 'nueva reunión', 'nueva cita'
        ],
        'screenshot': [
            'screenshot', 'captura de pantalla', 'foto de pantalla', 'pantallazo',
            'capturar pantalla', 'tomar foto', 'screenshot de pantalla'
        ],
        'notify': [
            'notificación', 'alerta', 'aviso', 'recordatorio', 'notificarme',
            'avisarme', 'recuérdame', 'recuerdame'
        ],
        'history': [
            'historial', 'chat anterior', 'conversación anterior', 'lo que dijimos',
            'qué dijimos', 'mensajes anteriores'
        ],
        'export': [
            'exportar', 'guardar datos', 'backup', 'respaldo', 'descargar datos',
            'exportar chat', 'guardar conversación'
        ],
        'applescript_spotify': [
            'abrir spotify', 'spotify', 'poner spotify', 'reproducir spotify',
            'música en spotify', 'canción en spotify'
        ],
        'applescript_music': [
            'abrir música', 'apple music', 'poner música', 'reproducir música',
            'música', 'canción', 'playlist', 'lista de reproducción'
        ],
        'applescript_terminal': [
            'abrir terminal', 'terminal', 'consola', 'línea de comandos',
            'abrir la terminal'
        ],
        'applescript_calculator': [
            'abrir calculadora', 'calculadora', 'calcula', 'sumar', 'restar',
            'multiplicar', 'dividir'
        ],
        'applescript_settings': [
            'abrir configuración', 'abrir ajustes', 'configuración', 'ajustes',
            'preferencias del sistema', 'system settings', 'system preferences'
        ],
        'applescript_notes': [
            'abrir notas', 'notas', 'nueva nota', 'escribir nota'
        ],
        'applescript_reminders': [
            'abrir recordatorios', 'recordatorios', 'nuevo recordatorio'
        ],
        'applescript_photos': [
            'abrir fotos', 'fotos', 'ver fotos', 'abrir imágenes'
        ],
        'applescript_finder': [
            'abrir finder', 'abrir carpeta', 'nueva carpeta', 'carpeta',
            'archivos', 'documentos'
        ],
        'applescript_preview': [
            'abrir preview', 'preview', 'ver imagen', 'abrir pdf'
        ],
        'applescript_textedit': [
            'abrir textedit', 'textedit', 'editor de texto', 'nuevo documento'
        ],
        'applescript_volume_up': [
            'subir volumen', 'más volumen', 'aumentar volumen', 'volumen arriba',
            'más alto', 'sube el volumen', 'súbele el volumen'
        ],
        'applescript_volume_down': [
            'bajar volumen', 'menos volumen', 'disminuir volumen', 'volumen abajo',
            'más bajo', 'baja el volumen', 'bájale el volumen'
        ],
        'applescript_mute': [
            'silenciar', 'mute', 'sin sonido', 'apagar sonido'
        ],
        'applescript_brightness_up': [
            'subir brillo', 'más brillo', 'aumentar brillo', 'brillo arriba',
            'más luminoso', 'súbele el brillo'
        ],
        'applescript_brightness_down': [
            'bajar brillo', 'menos brillo', 'disminuir brillo', 'brillo abajo',
            'menos luminoso', 'bájale el brillo'
        ],
        'applescript_lock': [
            'bloquear pantalla', 'bloquear mac', 'bloquear computadora',
            'cerrar sesión', 'lock screen'
        ],
        'applescript_sleep': [
            'dormir', 'suspender', 'sleep', 'modo sueño', 'apagar pantalla'
        ],
        'applescript_shutdown': [
            'apagar', 'shutdown', 'apagar computadora', 'apagar mac'
        ],
        'applescript_restart': [
            'reiniciar', 'restart', 'reiniciar mac', 'reiniciar computadora'
        ],
        'applescript_desktop': [
            'mostrar escritorio', 'escritorio', 'desktop', 'ver escritorio',
            'minimizar todo'
        ],
        'applescript_copy': [
            'copiar', 'copia esto', 'copiar selección', 'command c'
        ],
        'applescript_paste': [
            'pegar', 'pega esto', 'pegar selección', 'command v'
        ],
        'applescript_undo': [
            'deshacer', 'undo', 'deshacer cambio', 'ctrl z'
        ],
        'applescript_redo': [
            'rehacer', 'redo', 'rehacer cambio', 'ctrl shift z'
        ],
        'applescript_select_all': [
            'seleccionar todo', 'select all', 'seleccionar todo el texto',
            'command a'
        ],
        'applescript_close_window': [
            'cerrar ventana', 'cierra esto', 'cerrar esta ventana', 'command w'
        ],
        'applescript_quit_app': [
            'cerrar aplicación', 'salir', 'quit', 'cerrar app', 'command q'
        ],
        'applescript_new_tab': [
            'nueva pestaña', 'nueva tab', 'new tab', 'command t'
        ],
        'applescript_new_window': [
            'nueva ventana', 'new window', 'command n'
        ],
        'applescript_time': [
            'qué hora es', 'hora actual', 'qué hora', 'dime la hora'
        ],
        'applescript_date': [
            'qué día es', 'qué fecha es', 'fecha actual', 'dime la fecha',
            'día de hoy'
        ],
        'applescript_battery': [
            'batería', 'cuánta batería', 'nivel de batería', 'battery',
            'cuánto le queda', 'porcentaje de batería'
        ],
        'applescript_wifi': [
            'wifi', 'internet', 'conexión', 'red', 'conectar wifi',
            'estado wifi', 'quitar wifi'
        ],
        'applescript_bluetooth': [
            'bluetooth', 'conectar bluetooth', 'desconectar bluetooth',
            'airpods', 'auriculares'
        ],
        'applescript_whatsapp': [
            'abrir whatsapp', 'abre whatsapp', 'whatsapp', 'mensaje de whatsapp', 'abrir wasap',
            'wasap', 'whatsapp web', 'wpp'
        ],
        'applescript_vscode': [
            'abrir vscode', 'abre vscode', 'abrir visual studio code', 'vscode', 'visual studio code',
            'abrir code', 'code editor', 'editor de código'
        ],
        'applescript_zoom': [
            'abrir zoom', 'abre zoom', 'zoom', 'reunión de zoom', 'zoom meeting',
            'iniciar zoom', 'llamada de zoom'
        ],
        'applescript_teams': [
            'abrir teams', 'abre teams', 'microsoft teams', 'teams', 'reunión de teams',
            'llamada de teams', 'abrir microsoft teams'
        ],
        'applescript_chrome': [
            'abrir chrome', 'abre chrome', 'google chrome', 'chrome', 'navegador chrome',
            'abrir google chrome'
        ],
        'applescript_brave': [
            'abrir brave', 'abre brave', 'brave browser', 'brave', 'navegador brave'
        ],
        'applescript_arc': [
            'abrir arc', 'abre arc', 'arc browser', 'arc', 'navegador arc'
        ],
        'applescript_notion': [
            'abrir notion', 'abre notion', 'notion', 'notas notion', 'abrir notas notion'
        ],
        'applescript_slack': [
            'abrir slack', 'abre slack', 'slack', 'mensaje de slack', 'abrir slack workspace'
        ],
        'applescript_discord': [
            'abrir discord', 'abre discord', 'discord', 'abrir discord app', 'discord app'
        ],
        'applescript_telegram': [
            'abrir telegram', 'abre telegram', 'telegram', 'mensaje de telegram', 'abrir tg'
        ],
        'applescript_obsidian': [
            'abrir obsidian', 'abre obsidian', 'obsidian', 'vault obsidian', 'abrir vault'
        ],
    }

    import re
    for action, words in keywords.items():
        for word in words:
            # Word boundary: espacio, inicio o fin de string
            pattern = r"(?:^|\s)" + re.escape(word) + r"(?:\s|$)"
            if re.search(pattern, text_lower):
                return action
    return None


def _validate_script(script_code):
    trusted = ['tell application', 'tell application "System Events"', 'set volume', 'return (current date)', 'return (do shell script']
    bad = [';', '|', '&&', 'rm ', 'sudo ', 'curl ', 'wget ', 'python ', 'osascript']
    if any(b in script_code for b in bad):
        return False
    return any(script_code.strip().startswith(t) for t in trusted)

def _execute_applescript(script_name, script_code, response_text):
    """Ejecuta AppleScript y retorna resultado"""
    import subprocess
    if not _validate_script(script_code):
        return {
            'action': script_name,
            'params': {'script': script_code},
            'response': 'Script bloqueado por seguridad',
            'result': {'error': 'No permitido', 'success': 'false'},
            'method': 'applescript'
        }
    try:
        result = subprocess.run(
            ['osascript', '-e', script_code],
            capture_output=True,
            text=True,
            timeout=30
        )
        output = result.stdout.strip()
        error = result.stderr.strip() if result.returncode != 0 else None
        success = result.returncode == 0
        
        result_dict = _convert_result_to_strings({
            'output': output,
            'error': error,
            'success': success
        })
        
        return {
            'action': script_name,
            'params': {'script': script_code},
            'response': response_text if success else f"Error: {error}",
            'result': result_dict,
            'method': 'applescript'
        }
    except Exception as e:
        result_dict = _convert_result_to_strings({
            'error': str(e),
            'success': False
        })
        return {
            'action': script_name,
            'params': {'script': script_code},
            'response': f"Error ejecutando: {str(e)}",
            'result': result_dict,
            'method': 'applescript'
        }


def _execute_predefined_action(core, action, text):
    """Ejecuta acciones predefinidas de MACRON"""
    result = None
    response_text = "Acción completada"
    
    try:
        if action == 'focus_toggle':
            result = core.focus_toggle()
            response_text = "Modo Focus activado/desactivado"
        elif action == 'focus_status':
            result = core.focus_status()
            response_text = "Estado de Focus consultado"
        elif action == 'safari_search':
            query = text.replace('buscar', '').replace('sobre', '').replace('en safari', '').strip()
            result = core.safari_search(query)
            response_text = f"Buscando: {query}"
        elif action == 'safari_get_tabs':
            result = core.safari_get_tabs()
            response_text = "Tabs abiertas consultadas"
        elif action == 'safari_summarize':
            result = core.safari_summarize()
            response_text = "Página resumida"
        elif action == 'mail_get_inbox':
            result = core.mail_get_inbox(20)
            response_text = "Inbox consultado"
        elif action == 'mail_get_unread_count':
            result = core.mail_get_unread_count()
            response_text = "Emails no leídos consultados"
        elif action == 'mail_search':
            result = core.mail_search(text, 10)
            response_text = f"Buscando en Mail: {text}"
        elif action == 'calendar_today':
            result = core.calendar_today()
            response_text = "Eventos de hoy consultados"
        elif action == 'calendar_upcoming':
            result = core.calendar_upcoming(7)
            response_text = "Próximos eventos consultados"
        elif action == 'calendar_add_event':
            result = core.calendar_add_event(text, '', '')
            response_text = "Evento agregado al calendario"
        elif action == 'screenshot':
            result = core.screenshot()
            response_text = "Screenshot tomado"
        elif action == 'notify':
            result = core.notify('MACRON', text)
            response_text = "Notificación enviada"
        elif action == 'history':
            result = core.get_history()
            response_text = "Historial consultado"
        elif action == 'export':
            result = core.export_data('json')
            response_text = "Datos exportados"
        else:
            result = core.chat(text)
            response_text = result.get('text', 'Entendido') if isinstance(result, dict) else str(result)
    except Exception as e:
        result = {'error': str(e)}
        response_text = f"Error: {str(e)}"
    
    result_dict = _convert_result_to_strings(result if isinstance(result, dict) else {'text': str(result)})
    
    return {
        'action': action,
        'params': {},
        'response': response_text,
        'result': result_dict,
        'method': 'predefined'
    }



def _get_key():
    key_file = os.path.expanduser('~/Documents/MACRON/.macron_key')
    if os.path.exists(key_file):
        with open(key_file, 'rb') as f:
            return f.read()
    key = Fernet.generate_key()
    with open(key_file, 'wb') as f:
        f.write(key)
    return key

def _save_history(entry, filepath):
    try:
        history = []
        if os.path.exists(filepath):
            with open(filepath, 'rb') as f:
                encrypted = f.read()
                if encrypted:
                    fernet = Fernet(_get_key())
                    decrypted = fernet.decrypt(encrypted)
                    history = json.loads(decrypted.decode())
        history.append(entry)
        fernet = Fernet(_get_key())
        encrypted = fernet.encrypt(json.dumps(history).encode())
        with open(filepath, 'wb') as f:
            f.write(encrypted)
        print(f"[History] Guardado cifrado: {len(history)} entradas")
    except Exception as e:
        print(f"[History] Error guardando: {e}")

@app.route('/api/voice-action', methods=['POST'])
def voice_action():
    data = request.get_json() or {}
    text = data.get('text', '').strip()
    
    # Guardar en memoria
    _add_to_memory('user', text)
    
    # Obtener contexto
    memory_context = _get_memory_context()
    
    # Si hay contexto, enriquecer la respuesta
    if memory_context and len(_conversation_memory) > 1:
        print(f"[Memory] Contexto: {len(_conversation_memory)} mensajes")
    """Voice-to-Action UNIVERSAL: router expandido + AppleScript"""
    try:
        data = request.get_json() or {}
        text = data.get('text', '').strip()
        
        if not text:
            return jsonify({'error': 'No text provided'}), 400
        
        # === LOG HISTORIAL ===
        import json, os
        from datetime import datetime
        history_file = os.path.expanduser('~/Documents/MACRON/voice_history.json')
        history_entry = {
            'timestamp': datetime.now().isoformat(),
            'text': text,
            'action': None,
            'method': None
        }
        
        text_lower = text.lower()
        
        # === FASE 1: Router expandido ===
        routed = _route_voice_action(text_lower)
        
        if routed:
            core = get_macron_core()
            
            # Acciones predefinidas de MACRON
            if routed.startswith('focus_') or routed.startswith('safari_') or routed.startswith('mail_') or routed.startswith('calendar_') or routed in ['screenshot', 'notify', 'history', 'export']:
                result = _execute_predefined_action(core, routed, text)
                result['original_text'] = text
                history_entry['action'] = routed
                history_entry['method'] = 'predefined'
                _save_history(history_entry, history_file)
                return jsonify(result)
            
            # Acciones AppleScript
            scripts = {
                'applescript_spotify': ('Abriendo Spotify', 'tell application "Spotify" to activate'),
                'applescript_music': ('Abriendo Apple Music', 'tell application "Music" to activate'),
                'applescript_terminal': ('Abriendo Terminal', 'tell application "Terminal" to activate'),
                'applescript_calculator': ('Abriendo Calculadora', 'tell application "Calculator" to activate'),
                'applescript_settings': ('Abriendo Configuración', 'tell application "System Settings" to activate'),
                'applescript_notes': ('Abriendo Notas', 'tell application "Notes" to activate'),
                'applescript_reminders': ('Abriendo Recordatorios', 'tell application "Reminders" to activate'),
                'applescript_photos': ('Abriendo Fotos', 'tell application "Photos" to activate'),
                'applescript_finder': ('Abriendo Finder', 'tell application "Finder" to activate'),
                'applescript_preview': ('Abriendo Preview', 'tell application "Preview" to activate'),
                'applescript_textedit': ('Abriendo TextEdit', 'tell application "TextEdit" to activate'),
                'applescript_volume_up': ('Subiendo volumen', 'set volume output volume (output volume of (get volume settings) + 10)'),
                'applescript_volume_down': ('Bajando volumen', 'set volume output volume (output volume of (get volume settings) - 10)'),
                'applescript_mute': ('Silenciando', 'set volume with output muted'),
                'applescript_brightness_up': ('Subiendo brillo', 'tell application "System Events" to key code 144'),
                'applescript_brightness_down': ('Bajando brillo', 'tell application "System Events" to key code 145'),
                'applescript_lock': ('Bloqueando pantalla', 'tell application "System Events" to keystroke "q" using {command down, control down}'),
                'applescript_sleep': ('Suspendiendo', 'tell application "System Events" to sleep'),
                'applescript_shutdown': ('Apagando...', 'tell application "System Events" to shut down'),
                'applescript_restart': ('Reiniciando...', 'tell application "System Events" to restart'),
                'applescript_desktop': ('Mostrando escritorio', 'tell application "System Events" to key code 103'),
                'applescript_copy': ('Copiando', 'tell application "System Events" to keystroke "c" using command down'),
                'applescript_paste': ('Pegando', 'tell application "System Events" to keystroke "v" using command down'),
                'applescript_undo': ('Deshaciendo', 'tell application "System Events" to keystroke "z" using command down'),
                'applescript_redo': ('Rehaciendo', 'tell application "System Events" to keystroke "z" using {command down, shift down}'),
                'applescript_select_all': ('Seleccionando todo', 'tell application "System Events" to keystroke "a" using command down'),
                'applescript_close_window': ('Cerrando ventana', 'tell application "System Events" to keystroke "w" using command down'),
                'applescript_quit_app': ('Cerrando aplicación', 'tell application "System Events" to keystroke "q" using command down'),
                'applescript_new_tab': ('Nueva pestaña', 'tell application "System Events" to keystroke "t" using command down'),
                'applescript_new_window': ('Nueva ventana', 'tell application "System Events" to keystroke "n" using command down'),
                'applescript_time': ('Consultando hora', 'return (current date) as string'),
                'applescript_date': ('Consultando fecha', 'return (current date) as string'),
                'applescript_battery': ('Consultando batería', 'return (do shell script "pmset -g batt")'),
                'applescript_wifi': ('Consultando WiFi', 'return (do shell script "networksetup -getairportpower en0")'),
                'applescript_bluetooth': ('Consultando Bluetooth', 'return (do shell script "system_profiler SPBluetoothDataType | grep Power")'),
                'applescript_whatsapp': ('Abriendo WhatsApp', 'tell application "WhatsApp" to activate'),
                'applescript_vscode': ('Abriendo VS Code', 'tell application "Visual Studio Code" to activate'),
                'applescript_zoom': ('Abriendo Zoom', 'tell application "zoom.us" to activate'),
                'applescript_teams': ('Abriendo Microsoft Teams', 'tell application "Microsoft Teams" to activate'),
                'applescript_chrome': ('Abriendo Google Chrome', 'tell application "Google Chrome" to activate'),
                'applescript_brave': ('Abriendo Brave', 'tell application "Brave Browser" to activate'),
                'applescript_arc': ('Abriendo Arc', 'tell application "Arc" to activate'),
                'applescript_notion': ('Abriendo Notion', 'tell application "Notion" to activate'),
                'applescript_slack': ('Abriendo Slack', 'tell application "Slack" to activate'),
                'applescript_discord': ('Abriendo Discord', 'tell application "Discord" to activate'),
                'applescript_telegram': ('Abriendo Telegram', 'tell application "Telegram" to activate'),
                'applescript_obsidian': ('Abriendo Obsidian', 'tell application "Obsidian" to activate'),
            }
            
            if routed in scripts:
                response, script = scripts[routed]
                result = _execute_applescript(routed, script, response)
                result['original_text'] = text
                history_entry['action'] = routed
                history_entry['method'] = 'applescript'
                _save_history(history_entry, history_file)
                return jsonify(result)
            
            # Comandos personalizados
            if routed == 'custom_command' and isinstance(scripts, tuple) and scripts[0] == 'custom_command':
                cmd = scripts[1]
                result = _execute_applescript('custom_' + cmd['id'], cmd['applescript'], cmd['response'])
                result['original_text'] = text
                history_entry['action'] = 'custom_' + cmd['name']
                history_entry['method'] = 'custom'
                _save_history(history_entry, history_file)
                return jsonify(result)
        
        # === FASE 2: Fallback al chat general ===
        core = get_macron_core()
        result = core.chat(text)
        response = result.get('text', 'Entendido') if isinstance(result, dict) else str(result)
        
        history_entry['action'] = 'chat'
        history_entry['method'] = 'chat'
        _save_history(history_entry, history_file)
        return jsonify({
            'action': 'chat',
            'params': {},
            'response': response,
            'result': result if isinstance(result, dict) else {'text': str(result)},
            'original_text': text,
            'method': 'chat'
        })
        result = _convert_result_to_strings(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
@app.route('/api/focus/toggle', methods=['POST'])
def focus_toggle():
    try:
        core = get_macron_core()
        result = core.focus_toggle()
        st = core.focus_status()
        return jsonify({
            'result': result,
            'active': st['active'],
            'remaining_minutes': st['remaining_minutes']
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500




@app.route('/api/memory', methods=['GET'])
def get_memory():
    return jsonify({
        'memory': _conversation_memory,
        'count': len(_conversation_memory)
    })

@app.route('/api/memory/clear', methods=['POST'])
def clear_memory():
    global _conversation_memory
    _conversation_memory = []
    try:
        import os
        mem_file = os.path.expanduser('~/Documents/MACRON/conversation_memory.json')
        if os.path.exists(mem_file):
            os.remove(mem_file)
    except:
        pass
    return jsonify({'success': True})

@app.route('/api/screen-sharing', methods=['GET'])
def screen_sharing():
    import subprocess
    try:
        result = subprocess.run(['pgrep', '-x', 'ZoomMeetings|ScreenSharing|ReplayKitAgent'], 
                               capture_output=True, text=True, timeout=2)
        is_sharing = len(result.stdout.strip()) > 0
        return jsonify({'is_sharing': is_sharing})
    except:
        return jsonify({'is_sharing': False})

@app.route('/api/custom-commands', methods=['GET', 'POST', 'DELETE'])
def custom_commands():
    import json, os
    commands_file = os.path.expanduser('~/Documents/MACRON/custom_commands.json')
    if request.method == 'GET':
        try:
            with open(commands_file, 'r') as f:
                return jsonify({'commands': json.load(f)})
        except:
            return jsonify({'commands': []})
    elif request.method == 'POST':
        data = request.get_json() or {}
        new_cmd = {
            'id': __import__('datetime').datetime.now().isoformat(),
            'name': data.get('name', ''),
            'keywords': data.get('keywords', []),
            'applescript': data.get('applescript', ''),
            'response': data.get('response', 'Listo')
        }
        commands = []
        if os.path.exists(commands_file):
            with open(commands_file, 'r') as f:
                commands = json.load(f)
        commands.append(new_cmd)
        with open(commands_file, 'w') as f:
            json.dump(commands, f, indent=2, ensure_ascii=False)
        return jsonify({'success': True, 'command': new_cmd})
    elif request.method == 'DELETE':
        cmd_id = request.args.get('id')
        if not cmd_id:
            return jsonify({'error': 'No id provided'}), 400
        commands = []
        if os.path.exists(commands_file):
            with open(commands_file, 'r') as f:
                commands = json.load(f)
        commands = [c for c in commands if c.get('id') != cmd_id]
        with open(commands_file, 'w') as f:
            json.dump(commands, f, indent=2, ensure_ascii=False)
        return jsonify({'success': True})

@app.route('/api/history')
def history_list():
    try:
        core = get_macron_core()
        conversations = core.history_list()
        return jsonify({'conversations': conversations})
    except Exception as e:
        return jsonify({'error': str(e), 'conversations': []}), 500

@app.route('/api/export', methods=['POST'])
def export_chat():
    try:
        data = request.get_json()
        fmt = data.get('format', 'json')
        core = get_macron_core()
        result = core.export_conversation(data.get('session_id', 'default'), fmt)
        return jsonify({'success': True, 'result': result})
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/plugins')
def plugins_list():
    try:
        core = get_macron_core()
        plugins = core.plugins_list()
        return jsonify({'plugins': plugins})
    except Exception as e:
        return jsonify({'error': str(e), 'plugins': []}), 500

@app.route('/api/plugins/<name>/run', methods=['POST'])
def plugin_run(name):
    try:
        data = request.get_json() or {}
        core = get_macron_core()
        result = core.plugin_run(name, **data)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/analytics')
def analytics():
    try:
        core = get_macron_core()
        stats = core.analytics_summary()
        return jsonify(stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/calendar/event', methods=['POST'])
def calendar_add():
    try:
        data = request.get_json()
        core = get_macron_core()
        from datetime import datetime
        start = datetime.fromisoformat(data.get('start_date', datetime.now().isoformat()))
        result = core.calendar_add_event(data.get('title', 'Evento MACRON'), start, data.get('notes', ''))
        return jsonify({'success': result})
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/notify', methods=['POST'])
def notify():
    try:
        data = request.get_json()
        core = get_macron_core()
        result = core.notify(data.get('title', 'MACRON'), data.get('message', ''))
        return jsonify({'success': result})
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/safari/tabs')
def safari_tabs():
    try:
        core = get_macron_core()
        tabs = core.safari_get_tabs()
        active = core.safari_get_active_tab()
        return jsonify({'tabs': tabs, 'active': active, 'count': len(tabs)})
    except Exception as e:
        return jsonify({'error': str(e), 'tabs': [], 'active': None}), 500

@app.route('/api/safari/summarize')
def safari_summarize():
    try:
        core = get_macron_core()
        result = core.safari_summarize()
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e), 'summary': ''}), 500

@app.route('/api/safari/search', methods=['POST'])
def safari_search():
    try:
        data = request.get_json()
        query = data.get('query', '')
        core = get_macron_core()
        result = core.safari_search(query)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/safari/save', methods=['POST'])
def safari_save():
    try:
        data = request.get_json() or {}
        core = get_macron_core()
        result = core.safari_save(notes=data.get('notes', ''))
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/api/safari/readlater')
def safari_readlater():
    try:
        core = get_macron_core()
        items = core.safari_read_later_list()
        return jsonify({'items': items, 'count': len(items)})
    except Exception as e:
        return jsonify({'error': str(e), 'items': []}), 500

@app.route('/api/safari/open', methods=['POST'])
def safari_open():
    try:
        data = request.get_json()
        url = data.get('url', '')
        core = get_macron_core()
        result = core.safari_open_url(url)
        return jsonify({'success': True, 'result': result})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mail/inbox')
def mail_inbox():
    try:
        core = get_macron_core()
        limit = request.args.get('limit', 10, type=int)
        emails = core.mail_get_inbox(limit)
        return jsonify({'emails': emails, 'count': len(emails)})
    except Exception as e:
        return jsonify({'error': str(e), 'emails': []}), 500

@app.route('/api/mail/unread')
def mail_unread():
    try:
        core = get_macron_core()
        count = core.mail_get_unread_count()
        return jsonify({'unread_count': count})
    except Exception as e:
        return jsonify({'error': str(e), 'unread_count': 0}), 500

@app.route('/api/mail/summarize')
def mail_summarize():
    try:
        core = get_macron_core()
        result = core.mail_summarize()
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e), 'summary': ''}), 500

@app.route('/api/mail/search', methods=['POST'])
def mail_search():
    try:
        data = request.get_json()
        query = data.get('query', '')
        limit = data.get('limit', 10)
        core = get_macron_core()
        results = core.mail_search(query, limit)
        return jsonify({'results': results, 'count': len(results)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/finder/desktop')
def finder_desktop():
    try:
        core = get_macron_core()
        files = core.finder_desktop()
        return jsonify({'files': files, 'count': len(files)})
    except Exception as e:
        return jsonify({'error': str(e), 'files': []}), 500

@app.route('/api/finder/downloads')
def finder_downloads():
    try:
        core = get_macron_core()
        files = core.finder_downloads()
        return jsonify({'files': files, 'count': len(files)})
    except Exception as e:
        return jsonify({'error': str(e), 'files': []}), 500

@app.route('/api/finder/recent')
def finder_recent():
    try:
        core = get_macron_core()
        limit = request.args.get('limit', 10, type=int)
        files = core.finder_recent(limit)
        return jsonify({'files': files, 'count': len(files)})
    except Exception as e:
        return jsonify({'error': str(e), 'files': []}), 500

@app.route('/api/finder/search', methods=['POST'])
def finder_search():
    try:
        data = request.get_json()
        query = data.get('query', '')
        limit = data.get('limit', 20)
        core = get_macron_core()
        results = core.finder_search(query, limit)
        return jsonify({'results': results, 'count': len(results)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/calendar/today')
def calendar_today_api():
    try:
        core = get_macron_core()
        events = core.calendar_today()
        return jsonify({'events': events, 'count': len(events)})
    except Exception as e:
        return jsonify({'error': str(e), 'events': []}), 500

@app.route('/api/calendar/upcoming')
def calendar_upcoming_api():
    try:
        core = get_macron_core()
        days = request.args.get('days', 7, type=int)
        limit = request.args.get('limit', 10, type=int)
        events = core.calendar_upcoming(days, limit)
        return jsonify({'events': events, 'count': len(events), 'days': days})
    except Exception as e:
        return jsonify({'error': str(e), 'events': []}), 500

@app.route('/api/calendar/search', methods=['POST'])
def calendar_search_api():
    try:
        core = get_macron_core()
        data = request.get_json()
        query = data.get('query', '')
        days = data.get('days', 30)
        events = core.calendar_search(query, days)
        return jsonify({'events': events, 'count': len(events)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/notes/list')
def notes_list_api():
    try:
        core = get_macron_core()
        limit = request.args.get('limit', 10, type=int)
        notes = core.notes_list(limit)
        return jsonify({'notes': notes, 'count': len(notes)})
    except Exception as e:
        return jsonify({'error': str(e), 'notes': []}), 500

@app.route('/api/notes/search', methods=['POST'])
def notes_search_api():
    try:
        core = get_macron_core()
        data = request.get_json()
        query = data.get('query', '')
        limit = data.get('limit', 10)
        notes = core.notes_search(query, limit)
        return jsonify({'notes': notes, 'count': len(notes)})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/notes/content', methods=['POST'])
def notes_content_api():
    try:
        core = get_macron_core()
        data = request.get_json()
        title = data.get('title', '')
        result = core.notes_content(title)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/reminders/pending')
def reminders_pending_api():
    try:
        core = get_macron_core()
        list_name = request.args.get('list', 'Recordatorios')
        limit = request.args.get('limit', 10, type=int)
        reminders = core.reminders_pending(list_name, limit)
        return jsonify({'reminders': reminders, 'count': len(reminders)})
    except Exception as e:
        return jsonify({'error': str(e), 'reminders': []}), 500

@app.route('/api/reminders/create', methods=['POST'])
def reminders_create_api():
    try:
        core = get_macron_core()
        data = request.get_json()
        title = data.get('title', '')
        list_name = data.get('list', 'Recordatorios')
        notes = data.get('notes', '')
        result = core.reminders_create(title, list_name, notes=notes)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/agent/summary')
def agent_summary_api():
    try:
        core = get_macron_core()
        summary = core.agent_daily_summary()
        return jsonify(summary)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/monitor/report')
def monitor_report_api():
    try:
        core = get_macron_core()
        report = core.monitor_report()
        return jsonify(report)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/plugins/list')
def plugins_list_api():
    try:
        core = get_macron_core()
        plugins = core.plugin_list()
        return jsonify({'plugins': plugins, 'count': len(plugins)})
    except Exception as e:
        return jsonify({'error': str(e), 'plugins': []}), 500

@app.route('/api/plugins/run', methods=['POST'])
def plugins_run_api():
    try:
        core = get_macron_core()
        data = request.get_json()
        name = data.get('name', '')
        args = data.get('args', None)
        result = core.plugin_run(name, args)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print('='*50)
    print('  MACRON UI v3.1 - http://localhost:5001')
    print('  Core conectado - 20+ funcionalidades activas')
    print('='*50)
    app.run(host='0.0.0.0', port=5001, debug=False, threaded=False)