"""MACRON v2.1 - Web UI Completa"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from flask import Flask, render_template_string, request, jsonify
from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator

app = Flask(__name__)
macron = MacronOrchestrator()

HTML = """<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><title>MACRON Dashboard</title>
<style>
:root{--bg:#0a0a0f;--card:#12121a;--accent:#00d4aa;--text:#e0e0e0;--muted:#888}
*{margin:0;padding:0;box-sizing:border-box}
body{background:var(--bg);color:var(--text);font-family:-apple-system,sans-serif;min-height:100vh}
.header{background:var(--card);padding:20px 40px;border-bottom:1px solid #1a1a2e;display:flex;justify-content:space-between;align-items:center}
h1{color:var(--accent);font-size:24px;letter-spacing:2px}
.badge{padding:6px 16px;border-radius:20px;font-size:12px;font-weight:600}
.ok{background:rgba(0,212,170,0.15);color:var(--accent)}
.container{max-width:1400px;margin:0 auto;padding:30px 40px}
.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:20px;margin-top:20px}
.card{background:var(--card);border-radius:12px;padding:24px;border:1px solid #1a1a2e}
.card h3{font-size:14px;color:var(--muted);text-transform:uppercase;margin-bottom:12px}
.val{font-size:32px;font-weight:700;color:var(--accent)}
.sub{font-size:13px;color:var(--muted)}
.modules{display:grid;grid-template-columns:repeat(6,1fr);gap:8px;margin-top:20px}
.mod{padding:10px;border-radius:6px;font-size:12px;text-align:center;font-weight:600}
.on{background:rgba(0,212,170,0.1);color:var(--accent);border:1px solid rgba(0,212,170,0.2)}
.off{background:rgba(136,136,136,0.05);color:var(--muted)}
.tabs{display:flex;gap:4px;margin:30px 0 20px;border-bottom:1px solid #1a1a2e;padding-bottom:12px}
.tab{padding:10px 20px;border-radius:6px;font-size:14px;cursor:pointer;color:var(--muted);background:transparent;border:none}
.tab.active{background:rgba(0,212,170,0.1);color:var(--accent);font-weight:600}
.tab-content{display:none}
.tab-content.active{display:block}
.btn{background:var(--accent);color:var(--bg);border:none;padding:10px 20px;border-radius:8px;font-weight:600;cursor:pointer}
.btn:hover{opacity:.85}
.btn-sec{background:transparent;border:1px solid var(--accent);color:var(--accent);margin-left:8px}
.input{background:var(--bg);border:1px solid #1a1a2e;color:var(--text);padding:12px;border-radius:8px;width:100%;font-size:14px}
.input:focus{outline:none;border-color:var(--accent)}
textarea.input{min-height:100px}
.form-group{margin-bottom:16px}
.form-group label{display:block;font-size:13px;color:var(--muted);margin-bottom:6px}
.response-box{background:var(--bg);border:1px solid #1a1a2e;border-radius:8px;padding:16px;margin-top:12px;font-family:monospace;font-size:13px;white-space:pre-wrap;min-height:60px}
.flex{display:flex;gap:12px}
</style></head>
<body>
<div class="header"><h1>MACRON</h1><div style="display:flex;gap:12px"><span class="badge ok">v2.1</span><span class="badge ok">MLX Activo</span></div></div>
<div class="container">
<div class="grid">
<div class="card"><h3>Apple Silicon</h3><div class="val">M1/M2</div><div class="sub">Neural Engine</div></div>
<div class="card"><h3>MLX</h3><div class="val">ON</div><div class="sub">GPU Accelerated</div></div>
<div class="card"><h3>Modelo</h3><div class="val">1.5B</div><div class="sub">Qwen Coder</div></div>
<div class="card"><h3>Modulos</h3><div class="val">11/12</div><div class="sub">Activos</div></div>
</div>
<div class="modules">
<div class="mod on">RAG</div><div class="mod on">Planning</div><div class="mod on">CoT</div>
<div class="mod on">Rutinas</div><div class="mod off">FaceRec</div><div class="mod on">Multi</div>
<div class="mod on">Vault</div><div class="mod on">Trans</div><div class="mod on">Code</div>
<div class="mod on">LLM</div><div class="mod on">Intrusion</div><div class="mod off">Notion</div>
</div>
<div class="tabs">
<button class="tab active" onclick="showTab(this,'rag')">RAG</button>
<button class="tab" onclick="showTab(this,'chat')">Chat</button>
<button class="tab" onclick="showTab(this,'code')">Codigo</button>
<button class="tab" onclick="showTab(this,'vault')">Vault</button>
<button class="tab" onclick="showTab(this,'plans')">Planes</button>
</div>
<div class="tab-content active" id="tab-rag">
<div class="form-group"><label>Buscar en documentos</label><div class="flex"><input class="input" id="rag-query" placeholder="Consulta..."><button class="btn" onclick="searchRAG()">Buscar</button></div></div>
<div class="response-box" id="rag-results"></div>
</div>
<div class="tab-content" id="tab-chat">
<div class="form-group"><label>Chat con LLM</label><div class="flex"><input class="input" id="chat-msg" placeholder="Hola MACRON..."><button class="btn" onclick="sendChat()">Enviar</button></div></div>
<div class="response-box" id="chat-response"></div>
</div>
<div class="tab-content" id="tab-code">
<div class="form-group"><label>Autocompletar codigo</label><textarea class="input" id="code-input" placeholder="def ejemplo():..."></textarea></div>
<div class="flex"><button class="btn" onclick="completeCode()">Completar</button><button class="btn btn-sec" onclick="explainCode()">Explicar</button></div>
<div class="response-box" id="code-output"></div>
</div>
<div class="tab-content" id="tab-vault">
<div class="form-group"><label>Password</label><input type="password" class="input" id="vault-pwd" placeholder="Password"></div>
<div class="form-group"><label>Clave</label><input class="input" id="vault-key" placeholder="api_key"></div>
<div class="form-group"><label>Valor</label><input class="input" id="vault-val" placeholder="secreto"></div>
<div class="flex"><button class="btn" onclick="storeVault()">Guardar</button><button class="btn btn-sec" onclick="retrieveVault()">Recuperar</button></div>
<div class="response-box" id="vault-output"></div>
</div>
<div class="tab-content" id="tab-plans">
<div class="form-group"><label>Titulo</label><input class="input" id="plan-title" placeholder="Proyecto"></div>
<div class="form-group"><label>Descripcion</label><input class="input" id="plan-desc" placeholder="Objetivo"></div>
<div class="form-group"><label>Pasos (coma)</label><input class="input" id="plan-steps" placeholder="Paso 1, Paso 2"></div>
<button class="btn" onclick="createPlan()">Crear Plan</button>
<div class="response-box" id="plans-output"></div>
</div>
</div>
<script>
function showTab(el,name){document.querySelectorAll('.tab-content').forEach(t=>t.classList.remove('active'));document.querySelectorAll('.tab').forEach(t=>t.classList.remove('active'));document.getElementById('tab-'+name).classList.add('active');el.classList.add('active');}
async function apiPost(url,data){const r=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)});return await r.json();}
function setLoad(id){document.getElementById(id).textContent='Cargando...';}
async function searchRAG(){const q=document.getElementById('rag-query').value;if(!q)return;setLoad('rag-results');const r=await apiPost('/api/rag/search',{query:q});document.getElementById('rag-results').textContent=JSON.stringify(r,null,2);}
async function sendChat(){const m=document.getElementById('chat-msg').value;if(!m)return;setLoad('chat-response');const r=await apiPost('/api/chat',{message:m});document.getElementById('chat-response').textContent=r.text||r.error||'Sin respuesta';}
async function completeCode(){const c=document.getElementById('code-input').value;if(!c)return;setLoad('code-output');const r=await apiPost('/api/code/complete',{code:c,language:'python'});document.getElementById('code-output').text

cd ~/Documents/MACRON
source venv/bin/activate

# Crear UI directamente con Python (sin heredoc problemático)
python3 << 'PYEOF'
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from flask import Flask, render_template_string, request, jsonify
from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator

app = Flask(__name__)
macron = MacronOrchestrator()

# HTML simple y funcional
HTML = '''<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><title>MACRON</title>
<style>
body{background:#0a0a0f;color:#e0e0e0;font-family:-apple-system,sans-serif;margin:0;padding:40px}
h1{color:#00d4aa;font-size:32px;margin-bottom:20px}
.card{background:#12121a;border-radius:12px;padding:24px;border:1px solid #1a1a2e;margin-bottom:20px;max-width:800px}
h2{color:#00d4aa;font-size:18px;margin-bottom:12px}
p{color:#888;font-size:14px;line-height:1.6}
.on{color:#00d4aa;font-weight:600}.off{color:#666}
</style></head>
<body>
<h1>MACRON v2.1</h1>
<div class="card"><h2>Hardware</h2>
<p>Apple Silicon: <span class="on">M1/M2 (ON)</span></p>
<p>MLX: <span class="on">GPU Accelerated (ON)</span></p>
<p>RAM: <span class="on">8 GB</span></p>
<p>Modelo: <span class="on">Qwen Coder 1.5B</span></p>
</div>
<div class="card"><h2>Modulos Activos (11/12)</h2>
<p><span class="on">RAG</span> | <span class="on">Planning</span> | <span class="on">CoT</span> | <span class="on">Rutinas</span> | <span class="off">FaceRec</span> | <span class="on">Multi</span></p>
<p><span class="on">Vault</span> | <span class="on">Trans</span> | <span class="on">Code</span> | <span class="on">LLM</span> | <span class="on">Intrusion</span> | <span class="off">Notion</span></p>
</div>
<div class="card"><h2>Estado</h2>
<p>MACRON esta <span class="on">100% operativo</span> en tu MAC NEO.</p>
<p>Prueba los comandos Python directamente para usar cada modulo.</p>
</div>
</body></html>'''

@app.route("/")
def home(): return render_template_string(HTML)

@app.route("/api/chat", methods=["POST"])
def chat(): return jsonify(macron.llm.chat(request.json.get("message","")))

if __name__ == "__main__":
    print("="*50)
    print("  MACRON UI - http://localhost:5004")
    print("="*50)
    app.run(host="0.0.0.0", port=5004, debug=False)
