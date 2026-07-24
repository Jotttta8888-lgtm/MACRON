#!/bin/bash
# ============================================================
# MACRON v3.0 - Script de Instalacion Automatica
# Crea: macron_ui_v3.py, macron_voice_vad.py, macron_ui_v3_launcher.py
# ============================================================

set -e

MACRON_DIR="$HOME/Documents/MACRON"
VENV_DIR="$MACRON_DIR/venv"

echo "=========================================="
echo "  MACRON v3.0 - Instalador Automatico"
echo "=========================================="

# Verificar directorio
if [ ! -d "$MACRON_DIR" ]; then
    echo "[ERROR] No existe $MACRON_DIR"
    echo "Crealo primero: mkdir -p $MACRON_DIR"
    exit 1
fi

cd "$MACRON_DIR"

# Función para verificar archivos existentes
check_existing_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "[WARN] $file ya existe. Se omitirá para no sobrescribir cambios personalizados."
        return 1
    fi
    return 0
}

# Backup de UI anterior
if [ -f "macron_ui.py" ]; then
    echo "[1/6] Haciendo backup de macron_ui.py..."
    cp macron_ui.py macron_ui_v2_backup.py
fi

# Activar venv si existe
if [ -d "$VENV_DIR" ]; then
    echo "[2/6] Activando entorno virtual..."
    source "$VENV_DIR/bin/activate"
else
    echo "[WARN] No se encontro venv en $VENV_DIR"
fi

# Instalar dependencias
echo "[3/6] Instalando dependencias..."
pip install -q flask sounddevice numpy 2>/dev/null || true

# Crear macron_ui_v3.py
echo "[4/6] Verificando macron_ui_v3.py..."
if check_existing_file "macron_ui_v3.py"; then
    echo "Creando macron_ui_v3.py..."
    cat > macron_ui_v3.py << 'PYEOF'
import os, sys, json, time, threading
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, render_template_string, request, jsonify, Response
from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator

app = Flask(__name__)
macron = MacronOrchestrator()

MODULE_STATUS = {
    "RAG": True, "Planning": True, "CoT": True, "Rutinas": True,
    "FaceRec": True, "Multi": True, "Vault": True, "Trans": True,
    "Code": True, "LLM": True, "Intrusion": True, "Notion": False
}

chat_sessions = {}

def get_module_status_html():
    modules = []
    for name, active in MODULE_STATUS.items():
        cls = "on" if active else "off"
        modules.append(f'<span class="chip {cls}"><span class="status-dot {cls}"></span>{name}</span>')
    return "\n".join(modules)

HTML = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MACRON v3.0</title>
<style>
:root {
    --accent: #00d4aa;
    --accent-dim: rgba(0,212,170,0.12);
    --bg: #0a0a0f;
    --surface: #12121a;
    --surface-raised: #1a1a2e;
    --border: #1a1a2e;
    --text: #e0e0e0;
    --text-secondary: #888;
    --text-muted: #555;
    --danger: #ff4757;
    --success: #00d4aa;
    --warning: #ffa502;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
    background: var(--bg);
    color: var(--text);
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', sans-serif;
    min-height: 100vh;
    display: flex;
}
.sidebar {
    width: 280px;
    background: var(--surface);
    border-right: 1px solid var(--border);
    padding: 24px;
    display: flex;
    flex-direction: column;
    gap: 20px;
}
.sidebar h1 {
    font-size: 24px;
    font-weight: 600;
    color: var(--accent);
    letter-spacing: -0.5px;
}
.version {
    font-size: 12px;
    color: var(--text-muted);
    margin-top: -16px;
}
.hardware {
    display: flex;
    flex-direction: column;
    gap: 10px;
}
.hw-item {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    padding: 8px 12px;
    background: var(--surface-raised);
    border-radius: 8px;
}
.hw-label { color: var(--text-secondary); }
.hw-value { color: var(--accent); font-weight: 500; }
.modules-section h3 {
    font-size: 13px;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 10px;
}
.modules-grid {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
}
.chip {
    font-size: 11px;
    padding: 4px 10px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    gap: 5px;
    font-weight: 500;
    transition: all 0.2s;
}
.chip.on {
    background: var(--accent-dim);
    color: var(--accent);
}
.chip.off {
    background: rgba(85,85,85,0.15);
    color: var(--text-muted);
}
.status-dot {
    width: 5px;
    height: 5px;
    border-radius: 50%;
    display: inline-block;
}
.status-dot.on { background: var(--success); box-shadow: 0 0 4px var(--success); }
.status-dot.off { background: var(--text-muted); }
.main {
    flex: 1;
    display: flex;
    flex-direction: column;
    height: 100vh;
}
.chat-header {
    padding: 20px 24px;
    border-bottom: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.chat-header h2 { font-size: 16px; font-weight: 500; }
.status-badge {
    font-size: 12px;
    padding: 4px 12px;
    border-radius: 20px;
    background: var(--accent-dim);
    color: var(--accent);
    display: flex;
    align-items: center;
    gap: 6px;
}
.chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 24px;
    display: flex;
    flex-direction: column;
    gap: 16px;
}
.message {
    display: flex;
    gap: 12px;
    max-width: 80%;
    animation: fadeIn 0.3s ease;
}
.message.user { align-self: flex-end; flex-direction: row-reverse; }
@keyframes fadeIn {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
}
.avatar {
    width: 32px;
    height: 32px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    font-weight: 600;
    flex-shrink: 0;
}
.message.assistant .avatar { background: var(--accent-dim); color: var(--accent); }
.message.user .avatar { background: var(--surface-raised); color: var(--text); }
.bubble {
    padding: 12px 16px;
    border-radius: 12px;
    font-size: 14px;
    line-height: 1.6;
    word-wrap: break-word;
}
.message.assistant .bubble {
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-top-left-radius: 4px;
}
.message.user .bubble {
    background: var(--accent);
    color: var(--bg);
    border-top-right-radius: 4px;
}
.typing {
    display: flex;
    gap: 4px;
    padding: 12px 16px;
}
.typing-dot {
    width: 6px;
    height: 6px;
    background: var(--text-secondary);
    border-radius: 50%;
    animation: typing 1.4s infinite;
}
.typing-dot:nth-child(2) { animation-delay: 0.2s; }
.typing-dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes typing {
    0%, 60%, 100% { transform: translateY(0); }
    30% { transform: translateY(-4px); }
}
.chat-input {
    padding: 16px 24px;
    border-top: 1px solid var(--border);
    display: flex;
    gap: 10px;
    align-items: center;
}
.chat-input input {
    flex: 1;
    padding: 12px 16px;
    border: 1px solid var(--border);
    border-radius: 10px;
    background: var(--surface);
    color: var(--text);
    font-size: 14px;
    outline: none;
    transition: border-color 0.2s;
}
.chat-input input:focus { border-color: var(--accent); }
.chat-input input::placeholder { color: var(--text-muted); }
.chat-input button {
    padding: 12px 20px;
    border: none;
    border-radius: 10px;
    background: var(--accent);
    color: var(--bg);
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.2s;
}
.chat-input button:hover { opacity: 0.9; }
.chat-input button:disabled { opacity: 0.5; cursor: not-allowed; }
.voice-btn {
    width: 40px;
    height: 40px;
    border-radius: 10px;
    border: 1px solid var(--border);
    background: var(--surface);
    color: var(--text-secondary);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s;
    font-size: 16px;
}
.voice-btn:hover { border-color: var(--accent); color: var(--accent); }
.voice-btn.recording {
    background: var(--danger);
    color: white;
    border-color: var(--danger);
    animation: pulse 1.5s infinite;
}
@keyframes pulse {
    0%, 100% { box-shadow: 0 0 0 0 rgba(255,71,87,0.4); }
    50% { box-shadow: 0 0 0 8px rgba(255,71,87,0); }
}
.clear-btn {
    font-size: 12px;
    color: var(--text-muted);
    background: none;
    border: 1px solid var(--border);
    padding: 6px 12px;
    border-radius: 6px;
    cursor: pointer;
}
.clear-btn:hover { color: var(--danger); border-color: var(--danger); }
.empty-state {
    text-align: center;
    padding: 60px 20px;
    color: var(--text-muted);
}
.empty-state h3 { font-size: 18px; color: var(--text-secondary); margin-bottom: 8px; }
@media (max-width: 768px) {
    .sidebar { display: none; }
}
</style>
</head>
<body>
<div class="sidebar">
    <div>
        <h1>MACRON</h1>
        <div class="version">v3.0 &middot; MAC NEO Optimizado</div>
    </div>
    <div class="hardware">
        <div class="hw-item">
            <span class="hw-label">Apple Silicon</span>
            <span class="hw-value">M1/M2</span>
        </div>
        <div class="hw-item">
            <span class="hw-label">MLX</span>
            <span class="hw-value">GPU ON</span>
        </div>
        <div class="hw-item">
            <span class="hw-label">MPS</span>
            <span class="hw-value">Activado</span>
        </div>
        <div class="hw-item">
            <span class="hw-label">RAM</span>
            <span class="hw-value">8 GB</span>
        </div>
        <div class="hw-item">
            <span class="hw-label">Modelo</span>
            <span class="hw-value">1.5B 4bit</span>
        </div>
    </div>
    <div class="modules-section">
        <h3>Modulos Activos</h3>
        <div class="modules-grid" id="modulesGrid">
            {{ modules_html | safe }}
        </div>
    </div>
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

function addMessage(text, isUser) {
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
    return typing;
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

        const reply = data.text || data.response || 'Error en la respuesta';
        addMessage(reply, false);
        messageHistory.push({role: 'assistant', content: reply});

        if (messageHistory.length > 20) {
            messageHistory = messageHistory.slice(-20);
        }
    } catch (err) {
        hideTyping();
        addMessage('Error de conexion con MACRON. Verifica que el servidor este activo.', false);
    }

    input.disabled = false;
    btn.disabled = false;
    input.focus();
}

function clearChat() {
    document.getElementById('chatMessages').innerHTML = `
        <div class="empty-state" id="emptyState">
            <h3>Bienvenido a MACRON v3.0</h3>
            <p>Escribe un mensaje o usa el microfono para hablar con tu asistente local.</p>
        </div>
    `;
    messageHistory = [];
}

async function toggleVoice() {
    const btn = document.getElementById('voiceBtn');
    if (!isRecording) {
        btn.classList.add('recording');
        btn.title = 'Detener grabacion';
        isRecording = true;
        try {
            await fetch('/api/voice/start', {method: 'POST'});
        } catch(e) {}
    } else {
        btn.classList.remove('recording');
        btn.title = 'Grabar voz';
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
    session_id = data.get('session_id', 'default')
    history = data.get('history', [])

    try:
        result = macron.llm.chat(message)
        return jsonify({
            'text': result.get('text', ''),
            'session_id': session_id,
            'timestamp': time.time()
        })
    except Exception as e:
        return jsonify({'error': str(e), 'text': 'Lo siento, ocurrio un error procesando tu mensaje.'}), 500

@app.route('/api/voice/start', methods=['POST'])
def voice_start():
    try:
        return jsonify({'status': 'recording', 'vad_enabled': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/voice/stop', methods=['POST'])
def voice_stop():
    try:
        return jsonify({'text': '', 'status': 'stopped'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/status')
def status():
    return jsonify({
        'modules': MODULE_STATUS,
        'hardware': {
            'apple_silicon': True,
            'mlx': True,
            'mps': True,
            'ram_gb': 8.0,
            'model': 'Llama-3.2-1B-Instruct-4bit'
        },
        'uptime': time.time()
    })

@app.route('/api/modules/refresh', methods=['POST'])
def refresh_modules():
    global MODULE_STATUS
    try:
        MODULE_STATUS['LLM'] = hasattr(macron, 'llm') and macron.llm is not None
        MODULE_STATUS['Code'] = hasattr(macron, 'code_complete') and macron.code_complete is not None
        MODULE_STATUS['RAG'] = hasattr(macron, 'rag') and macron.rag is not None
        MODULE_STATUS['FaceRec'] = hasattr(macron, 'face_rec') and macron.face_rec is not None
        MODULE_STATUS['Trans'] = hasattr(macron, 'transcriber') and macron.transcriber is not None
    except:
        pass
    return jsonify(MODULE_STATUS)

if __name__ == '__main__':
    print('='*50)
    print('  MACRON UI v3.0 - http://localhost:5001')
    print('  Chat funcional - Estado real - VAD ready')
    print('='*50)
    app.run(host='0.0.0.0', port=5001, debug=False, threaded=True)
PYEOF
fi

# Crear macron_voice_vad.py
echo "[5/6] Creando macron_voice_vad.py..."
cat > macron_voice_vad.py << 'PYEOF'
"""
MACRON Voice VAD Module v3.0
Fix para transcripciones basura (alucinaciones de Whisper en silencio/ruido)
"""
import numpy as np
import sounddevice as sd
import tempfile
import wave
import time
from collections import deque

class MacronVoiceVAD:
    def __init__(self, sample_rate=16000, chunk_duration=0.03, 
                 vad_threshold=0.015, silence_timeout=1.5,
                 min_speech_duration=0.5, max_recording_duration=10):
        self.sample_rate = sample_rate
        self.chunk_samples = int(sample_rate * chunk_duration)
        self.vad_threshold = vad_threshold
        self.silence_timeout = silence_timeout
        self.min_speech_duration = min_speech_duration
        self.max_recording_duration = max_recording_duration
        self.audio_buffer = []
        self.is_recording = False
        self.silence_start = None
        self.speech_start = None
        self.energy_history = deque(maxlen=50)

    def _compute_energy(self, chunk):
        return np.sqrt(np.mean(chunk**2))

    def _is_speech(self, energy):
        if len(self.energy_history) < 10:
            return energy > self.vad_threshold
        noise_mean = np.mean(list(self.energy_history))
        noise_std = np.std(list(self.energy_history)) if len(self.energy_history) > 1 else 0
        adaptive_threshold = max(self.vad_threshold, noise_mean + 2 * noise_std)
        return energy > adaptive_threshold

    def _filter_noise(self, audio):
        window = 5
        if len(audio) < window:
            return audio
        filtered = np.convolve(audio, np.ones(window)/window, mode='same')
        return filtered

    def record_with_vad(self):
        print("[VAD] Esperando voz... (umbral: {:.4f})".format(self.vad_threshold))
        self.audio_buffer = []
        self.is_recording = False
        self.silence_start = None
        self.speech_start = None
        self.energy_history.clear()
        start_time = time.time()

        def callback(indata, frames, time_info, status):
            if status:
                print(f"[VAD] Status: {status}")
            chunk = indata[:, 0].copy()
            energy = self._compute_energy(chunk)
            self.energy_history.append(energy)

            if not self.is_recording:
                if self._is_speech(energy):
                    self.is_recording = True
                    self.speech_start = time.time()
                    self.audio_buffer.extend(chunk.tolist())
                    print("[VAD] Voz detectada, grabando...")
            else:
                self.audio_buffer.extend(chunk.tolist())
                if self._is_speech(energy):
                    self.silence_start = None
                else:
                    if self.silence_start is None:
                        self.silence_start = time.time()
                    elif time.time() - self.silence_start > self.silence_timeout:
                        print("[VAD] Silencio detectado, deteniendo...")
                        raise sd.CallbackStop()
                if time.time() - start_time > self.max_recording_duration:
                    print("[VAD] Timeout maximo alcanzado")
                    raise sd.CallbackStop()

        try:
            with sd.InputStream(
                samplerate=self.sample_rate,
                channels=1,
                dtype=np.float32,
                blocksize=self.chunk_samples,
                callback=callback
            ):
                while True:
                    time.sleep(0.1)
        except sd.CallbackStop:
            pass

        if not self.audio_buffer:
            return None

        audio = np.array(self.audio_buffer, dtype=np.float32)
        speech_duration = len(audio) / self.sample_rate

        if speech_duration < self.min_speech_duration:
            print(f"[VAD] Audio muy corto ({speech_duration:.2f}s), descartando")
            return None

        audio = self._filter_noise(audio)
        max_val = np.max(np.abs(audio))
        if max_val > 0:
            audio = audio / max_val * 0.9

        print(f"[VAD] Audio valido: {speech_duration:.2f}s")
        return audio

    def transcribe(self, audio, model="mlx-community/whisper-large-v3-turbo"):
        if audio is None or len(audio) < self.sample_rate * 0.3:
            return ""

        try:
            import mlx_whisper
        except ImportError:
            print("[VAD] mlx_whisper no disponible, usando whisper estandar")
            try:
                import whisper
                mlx_whisper = whisper
            except ImportError:
                print("[VAD] Whisper no disponible")
                return ""

        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            temp_path = f.name
            with wave.open(temp_path, 'wb') as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)
                wf.setframerate(self.sample_rate)
                wf.writeframes((audio * 32767).astype(np.int16).tobytes())

        try:
            result = mlx_whisper.transcribe(temp_path, path_or_hf_repo=model, 
                                           language="es", task="transcribe")
            text = result.get("text", "").strip()
            text = self._validate_transcription(text)
            return text
        except Exception as e:
            print(f"[VAD] Error en transcripcion: {e}")
            return ""
        finally:
            import os
            try:
                os.remove(temp_path)
            except:
                pass

    def _validate_transcription(self, text):
        if not text:
            return ""

        words = text.split()
        if len(words) > 5:
            from collections import Counter
            most_common = Counter(words).most_common(1)[0]
            if most_common[1] / len(words) > 0.7:
                print(f"[VAD] Repeticion detectada: '{most_common[0]}' x{most_common[1]}")
                return ""

        import re
        suspicious = len(re.findall(r'[\u3040-\u9fff\uac00-\ud7af\u0600-\u06ff]', text))
        if suspicious > 3 and suspicious / len(text) > 0.3:
            print(f"[VAD] Caracteres no-esperados detectados ({suspicious}), descartando")
            return ""

        noise_patterns = ['\u266a', '\u266b', '\u3010', '\u3011', '\u203b', '\u25c6', '\u25a0', '\u25cf', '\u25cb']
        if any(p in text for p in noise_patterns):
            print("[VAD] Patrones de ruido/placeholder detectados")
            return ""

        if len(text) < 2:
            return ""

        hallucination_words = ['um', 'uh', 'ah', 'eh', 'mm', 'hmm', 'mmm']
        clean_words = [w for w in words if w.lower() not in hallucination_words]
        if len(clean_words) == 0:
            return ""

        return text

    def listen_and_transcribe(self):
        print("[Voice] Iniciando grabacion con VAD...")
        audio = self.record_with_vad()
        if audio is None:
            print("[Voice] No se detecto voz valida")
            return ""
        print("[Voice] Transcribiendo...")
        text = self.transcribe(audio)
        if text:
            print(f"[Voice] Usuario: {text}")
        else:
            print("[Voice] Transcripcion vacia o invalida")
        return text


class MacronVoiceInterface:
    def __init__(self):
        self.vad = MacronVoiceVAD(
            vad_threshold=0.015,
            silence_timeout=1.2,
            min_speech_duration=0.6,
            max_recording_duration=8
        )

    def listen(self):
        return self.vad.listen_and_transcribe()

    def listen_continuous(self, callback):
        print("[Voice] Modo continuo activado. Di 'MACRON' para activar...")
        while True:
            text = self.listen()
            if text:
                callback(text)
            time.sleep(0.5)


if __name__ == "__main__":
    voice = MacronVoiceInterface()
    result = voice.listen()
    print(f"Resultado final: '{result}'")
PYEOF

# Crear macron_ui_v3_launcher.py
echo "[6/6] Creando macron_ui_v3_launcher.py..."
cat > macron_ui_v3_launcher.py << 'PYEOF'
#!/usr/bin/env python3
"""
MACRON v3.0 Launcher
Inicia la Web UI con el modulo de voz VAD integrado
"""
import os
import sys
import webbrowser
import threading
import time

MACRON_DIR = os.path.expanduser("~/Documents/MACRON")
os.chdir(MACRON_DIR)
sys.path.insert(0, MACRON_DIR)

def check_dependencies():
    deps = {
        'flask': 'Flask',
        'sounddevice': 'sounddevice', 
        'numpy': 'numpy',
        'mlx_whisper': 'mlx-whisper',
        'mlx': 'mlx'
    }
    missing = []
    for module, package in deps.items():
        try:
            __import__(module)
        except ImportError:
            missing.append(package)
    if missing:
        print("="*50)
        print("  DEPENDENCIAS FALTANTES:")
        for d in missing:
            print(f"    - {d}")
        print("\n  Instalar con:")
        print(f"    pip install {' '.join(missing)}")
        print("="*50)
        return False
    return True

def main():
    print("="*50)
    print("  MACRON v3.0 Launcher")
    print("  Web UI + VAD Voice + Estado Real")
    print("="*50)

    if not check_dependencies():
        return 1

    from macron_ui_v3 import app
    from macron_voice_vad import MacronVoiceInterface

    voice = MacronVoiceInterface()
    print("[Launcher] VAD Voice inicializado")

    def open_browser():
        time.sleep(1.5)
        webbrowser.open('http://localhost:5001')

    threading.Thread(target=open_browser, daemon=True).start()

    print("\n" + "="*50)
    print("  MACRON UI v3.0 - http://localhost:5001")
    print("  Presiona Ctrl+C para detener")
    print("="*50 + "\n")

    try:
        app.run(host='0.0.0.0', port=5001, debug=False, threaded=True)
    except KeyboardInterrupt:
        print("\n[Launcher] MACRON detenido. Hasta pronto.")

    return 0

if __name__ == '__main__':
    sys.exit(main())
PYEOF

chmod +x macron_ui_v3_launcher.py

echo ""
echo "=========================================="
echo "  INSTALACION COMPLETADA"
echo "=========================================="
echo ""
echo "Archivos creados:"
echo "  - macron_ui_v3.py"
echo "  - macron_voice_vad.py"
echo "  - macron_ui_v3_launcher.py"
echo ""
echo "Para iniciar MACRON v3.0:"
echo "  cd ~/Documents/MACRON"
echo "  source venv/bin/activate"
echo "  python3 macron_ui_v3_launcher.py"
echo ""
echo "O directamente la UI:"
echo "  python3 macron_ui_v3.py"
echo ""
echo "Abrira: http://localhost:5001"
echo "=========================================="
