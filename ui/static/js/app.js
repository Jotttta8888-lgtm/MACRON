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

refreshStatus();
document.getElementById('messageInput').focus();
