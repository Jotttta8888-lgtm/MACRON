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
            future = _llm_executor.submit(core.orchestrator.llm.chat, message)
            result = future.result(timeout=60)
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

if __name__ == '__main__':
    print('='*50)
    print('  MACRON UI v3.1 - http://localhost:5004')
    print('  Core conectado - 20+ funcionalidades activas')
    print('='*50)
    app.run(host='0.0.0.0', port=5004, debug=False, threaded=False)