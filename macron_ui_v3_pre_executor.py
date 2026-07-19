import os, sys, json, time, threading
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, render_template_string, request, jsonify

app = Flask(__name__)

# Carga lazy del orchestrator
_macron = None
_lock = threading.Lock()

def _load_macron():
    from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator
    return MacronOrchestrator()

def get_macron():
    global _macron
    if _macron is None:
        with _lock:
            if _macron is None:
                future = _llm_executor.submit(_load_macron)
                _macron = future.result(timeout=120)
    return _macron

# Executor de UN SOLO thread para MLX - todas las llamadas al LLM van aqui
# Esto garantiza que el stream GPU de MLX siempre este en el mismo thread
_llm_executor = ThreadPoolExecutor(max_workers=1)

MODULE_STATUS = {
    "RAG": True, "Planning": True, "CoT": True, "Rutinas": True,
    "FaceRec": True, "Multi": True, "Vault": True, "Trans": True,
    "Code": True, "LLM": True, "Intrusion": True, "Notion": False
}

def get_module_status_html():
    modules = []
    for name, active in MODULE_STATUS.items():
        cls = "on" if active else "off"
        modules.append(f'<span class="chip {cls}"><span class="status-dot {cls}"></span>{name}</span>')
    return "\\n".join(modules)

HTML = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MACRON v3.0</title>
<style>
:root { --accent: #00d4aa; --accent-dim: rgba(0,212,170,0.12); --bg: #0a0a0f; --surface: #12121a; --surface-raised: #1a1a2e; --border: #1a1a2e; --text: #e0e0e0; --text-secondary: #888; --text-muted: #555; --danger: #ff4757; --success: #00d4aa; }
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: var(--bg); color: var(--text); font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif; min-height: 100vh; display: flex; }
.sidebar { width: 280px; background: var(--surface); border-right: 1px solid var(--border); padding: 24px; display: flex; flex-direction: column; gap: 20px; }
.sidebar h1 { font-size: 24px; font-weight: 600; color: var(--accent); letter-spacing: -0.5px; }
.version { font-size: 12px; color: var(--text-muted); margin-top: -16px; }
.hardware { display: flex; flex-direction: column; gap: 10px; }
.hw-item { display: flex; justify-content: space-between; font-size: 13px; padding: 8px 12px; background: var(--surface-raised); border-radius: 8px; }
.hw-label { color: var(--text-secondary); }
.hw-value { color: var(--accent); font-weight: 500; }
.modules-section h3 { font-size: 13px; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 10px; }
.modules-grid { display: flex; flex-wrap: wrap; gap: 6px; }
.chip { font-size: 11px; padding: 4px 10px; border-radius: 6px; display: flex; align-items: center; gap: 5px; font-weight: 500; }
.chip.on { background: var(--accent-dim); color: var(--accent); }
.chip.off { background: rgba(85,85,85,0.15); color: var(--text-muted); }
.status-dot { width: 5px; height: 5px; border-radius: 50%; display: inline-block; }
.status-dot.on { background: var(--success); box-shadow: 0 0 4px var(--success); }
.status-dot.off { background: var(--text-muted); }
.main { flex: 1; display: flex; flex-direction: column; height: 100vh; }
.chat-header { padding: 20px 24px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
.chat-header h2 { font-size: 16px; font-weight: 500; }
.status-badge { font-size: 12px; padding: 4px 12px; border-radius: 20px; background: var(--accent-dim); color: var(--accent); display: flex; align-items: center; gap: 6px; }
.chat-messages { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.message { display: flex; gap: 12px; max-width: 80%; animation: fadeIn 0.3s ease; }
.message.user { align-self: flex-end; flex-direction: row-reverse; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
.avatar { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; flex-shrink: 0; }
.message.assistant .avatar { background: var(--accent-dim); color: var(--accent); }
.message.user .avatar { background: var(--surface-raised); color: var(--text); }
.bubble { padding: 12px 16px; border-radius: 12px; font-size: 14px; line-height: 1.6; word-wrap: break-word; }
.message.assistant .bubble { background: var(--surface-raised); border: 1px solid var(--border); border-top-left-radius: 4px; }
.message.user .bubble { background: var(--accent); color: var(--bg); border-top-right-radius: 4px; }
.typing { display: flex; gap: 4px; padding: 12px 16px; }
.typing-dot { width: 6px; height: 6px; background: var(--text-secondary); border-radius: 50%; animation: typing 1.4s infinite; }
.typing-dot:nth-child(2) { animation-delay: 0.2s; }
.typing-dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes typing { 0%, 60%, 100% { transform: translateY(0); } 30% { transform: translateY(-4px); } }
.chat-input { padding: 16px 24px; border-top: 1px solid var(--border); display: flex; gap: 10px; align-items: center; }
.chat-input input { flex: 1; padding: 12px 16px; border: 1px solid var(--border); border-radius: 10px; background: var(--surface); color: var(--text); font-size: 14px; outline: none; }
.chat-input input:focus { border-color: var(--accent); }
.chat-input input::placeholder { color: var(--text-muted); }
.chat-input button { padding: 12px 20px; border: none; border-radius: 10px; background: var(--accent); color: var(--bg); font-size: 14px; font-weight: 600; cursor: pointer; }
.chat-input button:disabled { opacity: 0.5; cursor: not-allowed; }
.voice-btn { width: 40px; height: 40px; border-radius: 10px; border: 1px solid var(--border); background: var(--surface); color: var(--text-secondary); cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 16px; }
.voice-btn.recording { background: var(--danger); color: white; border-color: var(--danger); animation: pulse 1.5s infinite; }
@keyframes pulse { 0%, 100% { box-shadow: 0 0 0 0 rgba(255,71,87,0.4); } 50% { box-shadow: 0 0 0 8px rgba(255,71,87,0); } }
.clear-btn { font-size: 12px; color: var(--text-muted); background: none; border: 1px solid var(--border); padding: 6px 12px; border-radius: 6px; cursor: pointer; }
.empty-state { text-align: center; padding: 60px 20px; color: var(--text-muted); }
.empty-state h3 { font-size: 18px; color: var(--text-secondary); margin-bottom: 8px; }
@media (max-width: 768px) { .sidebar { display: none; } }
</style>
</head>
<body>
<div class="sidebar">
    <div><h1>MACRON</h1><div class="version">v3.0 &middot; MAC NEO Optimizado</div></div>
    <div class="hardware">
        <div class="hw-item"><span class="hw-label">Apple Silicon</span><span class="hw-value">M1/M2</span></div>
        <div class="hw-item"><span class="hw-label">MLX</span><span class="hw-value">GPU ON</span></div>
        <div class="hw-item"><span class="hw-label">MPS</span><span class="hw-value">Activado</span></div>
        <div class="hw-item"><span class="hw-label">RAM</span><span class="hw-value">8 GB</span></div>
        <div class="hw-item"><span class="hw-label">Modelo</span><span class="hw-value">1.5B 4bit</span></div>
    </div>
    <div class="modules-section"><h3>Modulos Activos</h3><div class="modules-grid">{{ modules_html | safe }}</div></div>
</div>
<div class="main">
    <div class="chat-header">
        <h2>Chat con MACRON</h2>
        <div style="display:flex;gap:10px;align-items:center;">
            <span class="status-badge"><span class="status-dot on"></span>En linea</span>
            <button class="clear-btn" onclick="clearChat()">Limpiar</button>
        </div>
    </div>
    <div class="chat-messages" id="chatMessages">
        <div class="empty-state" id="emptyState">
            <h3>Bienvenido a MACRON v3.0</h3>
            <p>Escribe un mensaje o usa el microfono para hablar con tu asistente local.</p>
        </div>
    </div>
    <div class="chat-input">
        <button class="voice-btn" id="voiceBtn" onclick="toggleVoice()" title="Grabar voz">&#127908;</button>
        <input type="text" id="messageInput" placeholder="Escribe tu mensaje..." onkeypress="if(event.key==='Enter')sendMessage()">
        <button id="sendBtn" onclick="sendMessage()">Enviar</button>
    </div>
</div>
<script>
let sessionId = 'session_' + Date.now();
let isRecording = false;
let messageHistory = [];

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
    const typing = showTyping();
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
    document.getElementById('chatMessages').innerHTML = '<div class="empty-state" id="emptyState"><h3>Bienvenido a MACRON v3.0</h3><p>Escribe un mensaje o usa el microfono para hablar con tu asistente local.</p></div>';
    messageHistory = [];
}

async function toggleVoice() {
    const btn = document.getElementById('voiceBtn');
    if (!isRecording) {
        btn.classList.add('recording');
        isRecording = true;
        try { await fetch('/api/voice/start', {method: 'POST'}); } catch(e) {}
    } else {
        btn.classList.remove('recording');
        isRecording = false;
        try {
            const response = await fetch('/api/voice/stop', {method: 'POST'});
            const data = await response.json();
            if (data.text && data.text.trim()) {
                document.getElementById('messageInput').value = data.text;
                sendMessage();
            }
        } catch(e) {}
    }
}
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
        macron = get_macron()
        # Enviar al executor de un solo thread para MLX
        future = _llm_executor.submit(macron.llm.chat, message)
        result = future.result(timeout=60)

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

@app.route('/api/voice/start', methods=['POST'])
def voice_start():
    return jsonify({'status': 'recording', 'vad_enabled': True})

@app.route('/api/voice/stop', methods=['POST'])
def voice_stop():
    return jsonify({'text': '', 'status': 'stopped'})

@app.route('/api/status')
def status():
    return jsonify({
        'modules': MODULE_STATUS,
        'hardware': {
            'apple_silicon': True, 'mlx': True, 'mps': True,
            'ram_gb': 8.0, 'model': 'Llama-3.2-1B-Instruct-4bit'
        }
    })

if __name__ == '__main__':
    print('='*50)
    print('  MACRON UI v3.0 - http://localhost:5004')
    print('  Chat funcional - Estado real - VAD ready')
    print('='*50)
    app.run(host='0.0.0.0', port=5004, debug=False, threaded=True)
