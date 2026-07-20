#!/usr/bin/env python3
"""
MACRON Web UI v2.1
==================
Dashboard interactivo con tema oscuro estilo GitHub.
Ejecutar: python MACRON_WEB_UI_v2.1.py
Acceder: http://localhost:5000
"""

import os, sys, json
from pathlib import Path
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, render_template, jsonify, request
from MACRON_FUNCIONALIDADES_v2 import (
    MacronOrchestrator, MacronConfig, MacronRAG, MacronPlanning,
    MacronCoT, MacronRutinas, MacronVault, MacronMultiDevice
)

app = Flask(__name__)
macron = MacronOrchestrator()

# ============================================================
# HTML TEMPLATE (embedded)
# ============================================================

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MACRON - Dashboard</title>
<style>
:root{--bg:#0d1117;--surface:#161b22;--border:#30363d;--text:#c9d1d9;--muted:#8b949e;--accent:#58a6ff;--success:#238636;--warn:#d29922;--danger:#da3633;}
*{box-sizing:border-box;margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;}
body{background:var(--bg);color:var(--text);min-height:100vh;}
.header{background:var(--surface);border-bottom:1px solid var(--border);padding:16px 24px;display:flex;align-items:center;justify-content:space-between;}
.header h1{font-size:20px;font-weight:600;letter-spacing:-0.5px;}
.header .badge{background:var(--accent);color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;font-weight:600;}
.nav{background:var(--surface);border-right:1px solid var(--border);width:220px;min-height:calc(100vh - 60px);padding:16px 0;position:fixed;}
.nav a{display:block;padding:8px 24px;color:var(--text);text-decoration:none;font-size:14px;transition:0.15s;}
.nav a:hover{background:rgba(88,166,255,0.1);color:var(--accent);}
.nav a.active{border-left:2px solid var(--accent);background:rgba(88,166,255,0.05);}
.main{margin-left:220px;padding:24px;}
.card{background:var(--surface);border:1px solid var(--border);border-radius:8px;padding:20px;margin-bottom:16px;}
.card h3{font-size:16px;margin-bottom:12px;color:var(--text);}
.card p{color:var(--muted);font-size:14px;line-height:1.6;}
.btn{background:var(--accent);color:#fff;border:none;padding:8px 16px;border-radius:6px;cursor:pointer;font-size:14px;font-weight:500;transition:0.15s;}
.btn:hover{background:#79b8ff;}
.btn-secondary{background:var(--surface);border:1px solid var(--border);color:var(--text);}
.btn-secondary:hover{background:var(--border);}
.btn-danger{background:var(--danger);}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px;}
table{width:100%;border-collapse:collapse;font-size:13px;}
th,td{padding:10px 12px;text-align:left;border-bottom:1px solid var(--border);}
th{color:var(--muted);font-weight:500;font-size:12px;text-transform:uppercase;}
tr:hover{background:rgba(255,255,255,0.02);}
.status-dot{width:8px;height:8px;border-radius:50%;display:inline-block;margin-right:6px;}
.status-ok{background:var(--success);}
.status-warn{background:var(--warn);}
.status-off{background:var(--danger);}
input,select,textarea{background:var(--bg);border:1px solid var(--border);color:var(--text);padding:8px 12px;border-radius:6px;font-size:14px;width:100%;margin-bottom:12px;}
input:focus,select:focus,textarea:focus{outline:none;border-color:var(--accent);}
label{display:block;font-size:12px;color:var(--muted);margin-bottom:4px;text-transform:uppercase;}
pre{background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:12px;overflow-x:auto;font-size:13px;color:var(--text);}
.footer{text-align:center;padding:24px;color:var(--muted);font-size:12px;border-top:1px solid var(--border);margin-top:40px;}
@media(max-width:768px){.nav{width:100%;position:relative;min-height:auto;}.main{margin-left:0;}}
</style>
</head>
<body>
<div class="header">
  <h1>MACRON <span style="color:var(--muted);font-weight:400;">Agente IA Local</span></h1>
  <span class="badge">v2.0</span>
</div>
<div style="display:flex;">
  <nav class="nav">
    <a href="/" class="{{ 'active' if page=='dashboard' }}">Dashboard</a>
    <a href="/rag" class="{{ 'active' if page=='rag' }}">RAG Archivos</a>
    <a href="/planning" class="{{ 'active' if page=='planning' }}">Planificacion</a>
    <a href="/cot" class="{{ 'active' if page=='cot' }}">Chain-of-Thought</a>
    <a href="/rutinas" class="{{ 'active' if page=='rutinas' }}">Rutinas</a>
    <a href="/vault" class="{{ 'active' if page=='vault' }}">Vault</a>
    <a href="/devices" class="{{ 'active' if page=='devices' }}">Dispositivos</a>
    <a href="/status" class="{{ 'active' if page=='status' }}">Estado del Sistema</a>
  </nav>
  <main class="main">
    {% block content %}{% endblock %}
    <div class="footer">MACRON v2.0 | MAC NEO Optimizado | {{ now }}</div>
  </main>
</div>
</body>
</html>
"""

# ============================================================
# ROUTES
# ============================================================

@app.route("/")
def dashboard():
    status = macron.status()
    modules = status["modules"]
    return render_template_string(HTML_TEMPLATE + """
    {% block content %}
    <h2 style="margin-bottom:20px;">Dashboard</h2>
    <div class="grid">
      <div class="card">
        <h3>Hardware</h3>
        <p>RAM: {{ status.hardware.ram_gb }} GB<br>
        Apple Silicon: {{ "Si" if status.hardware.apple_silicon else "No" }}<br>
        MLX: {{ "Si" if status.hardware.mlx else "No" }}<br>
        Modelo: {{ status.hardware.model_size }}</p>
      </div>
      <div class="card">
        <h3>Modulos Activos</h3>
        <p>
        {% for name, active in modules.items() %}
          <span class="status-dot {{ 'status-ok' if active else 'status-off' }}"></span>{{ name }}<br>
        {% endfor %}
        </p>
      </div>
    </div>
    {% endblock %}
    """, page="dashboard", status=status, modules=modules, now=datetime.now().isoformat())

@app.route("/rag")
def rag_page():
    files = macron.rag.list_indexed()
    return render_template_string(HTML_TEMPLATE + """
    {% block content %}
    <h2 style="margin-bottom:20px;">RAG - Archivos Indexados</h2>
    <div class="card">
      <h3>Indexar Archivo</h3>
      <form action="/api/rag/index" method="post">
        <label>Ruta del archivo</label>
        <input type="text" name="path" placeholder="/Users/tu/documento.pdf" required>
        <button type="submit" class="btn">Indexar</button>
      </form>
    </div>
    <div class="card">
      <h3>Buscar</h3>
      <form action="/api/rag/search" method="post">
        <input type="text" name="query" placeholder="Buscar en documentos..." required>
        <button type="submit" class="btn">Buscar</button>
      </form>
    </div>
    <div class="card">
      <h3>Archivos Indexados ({{ files|length }})</h3>
      <table>
        <tr><th>Archivo</th><th>Accion</th></tr>
        {% for f in files %}
        <tr><td>{{ f }}</td><td><a href="/api/rag/delete?path={{ f }}" class="btn btn-danger" style="padding:4px 8px;font-size:12px;">Eliminar</a></td></tr>
        {% endfor %}
      </table>
    </div>
    {% endblock %}
    """, page="rag", files=files, now=datetime.now().isoformat())

@app.route("/planning")
def planning_page():
    plans = macron.planning.list()
    return render_template_string(HTML_TEMPLATE + """
    {% block content %}
    <h2 style="margin-bottom:20px;">Planificacion Verificada</h2>
    <div class="card">
      <h3>Nuevo Plan</h3>
      <form action="/api/planning/create" method="post">
        <label>Nombre</label><input type="text" name="name" required>
        <label>Descripcion</label><input type="text" name="desc">
        <label>Pasos (uno por linea)</label><textarea name="steps" rows="4" required></textarea>
        <button type="submit" class="btn">Crear Plan</button>
      </form>
    </div>
    <div class="card">
      <h3>Planes ({{ plans|length }})</h3>
      <table>
        <tr><th>ID</th><th>Nombre</th><th>Estado</th><th>Creado</th></tr>
        {% for p in plans %}
        <tr><td>{{ p.id }}</td><td>{{ p.name }}</td><td>{{ p.status }}</td><td>{{ p.created }}</td></tr>
        {% endfor %}
      </table>
    </div>
    {% endblock %}
    """, page="planning", plans=plans, now=datetime.now().isoformat())

@app.route("/rutinas")
def rutinas_page():
    rutinas = macron.rutinas.list()
    return render_template_string(HTML_TEMPLATE + """
    {% block content %}
    <h2 style="margin-bottom:20px;">Rutinas Programadas</h2>
    <div class="card">
      <h3>Nueva Rutina</h3>
      <form action="/api/rutinas/create" method="post">
        <label>Nombre</label><input type="text" name="name" required>
        <label>Descripcion</label><input type="text" name="desc">
        <label>Cron (ej: 0 2 * * *)</label><input type="text" name="cron" value="0 * * * *" required>
        <label>Tipo</label>
        <select name="type">
          <option value="shell">Shell</option>
          <option value="python">Python</option>
          <option value="notification">Notificacion</option>
          <option value="backup">Backup</option>
        </select>
        <label>Parametros (JSON)</label><textarea name="params" rows="3">{"command": "echo hello"}</textarea>
        <button type="submit" class="btn">Crear Rutina</button>
      </form>
    </div>
    <div class="card">
      <h3>Rutinas ({{ rutinas|length }})</h3>
      <table>
        <tr><th>ID</th><th>Nombre</th><th>Cron</th><th>Tipo</th><th>Activa</th></tr>
        {% for r in rutinas %}
        <tr><td>{{ r.id }}</td><td>{{ r.name }}</td><td>{{ r.cron }}</td><td>{{ r.type }}</td>
        <td><span class="status-dot {{ 'status-ok' if r.enabled else 'status-off' }}"></span></td></tr>
        {% endfor %}
      </table>
    </div>
    {% endblock %}
    """, page="rutinas", rutinas=rutinas, now=datetime.now().isoformat())

@app.route("/vault")
def vault_page():
    return render_template_string(HTML_TEMPLATE + """
    {% block content %}
    <h2 style="margin-bottom:20px;">Vault - Caja Fuerte</h2>
    <div class="card">
      <h3>Configurar Vault</h3>
      <form action="/api/vault/setup" method="post">
        <label>Password Maestro</label><input type="password" name="pwd" required>
        <button type="submit" class="btn">Configurar</button>
      </form>
    </div>
    <div class="card">
      <h3>Almacenar Valor</h3>
      <form action="/api/vault/store" method="post">
        <label>Clave</label><input type="text" name="key" required>
        <label>Valor</label><input type="text" name="value" required>
        <label>Password</label><input type="password" name="pwd" required>
        <button type="submit" class="btn">Guardar</button>
      </form>
    </div>
    <div class="card">
      <h3>Recuperar Valor</h3>
      <form action="/api/vault/retrieve" method="post">
        <label>Clave</label><input type="text" name="key" required>
        <label>Password</label><input type="password" name="pwd" required>
        <button type="submit" class="btn">Recuperar</button>
      </form>
    </div>
    {% endblock %}
    """, page="vault", now=datetime.now().isoformat())

@app.route("/status")
def status_page():
    s = macron.status()
    return render_template_string(HTML_TEMPLATE + """
    {% block content %}
    <h2 style="margin-bottom:20px;">Estado del Sistema</h2>
    <div class="card">
      <h3>JSON Completo</h3>
      <pre>{{ json }}</pre>
    </div>
    {% endblock %}
    """, page="status", json=json.dumps(s, indent=2), now=datetime.now().isoformat())

# ============================================================
# API ENDPOINTS
# ============================================================

@app.route("/api/status")
def api_status():
    return jsonify(macron.status())

@app.route("/api/rag/index", methods=["POST"])
def api_rag_index():
    path = request.form.get("path")
    return jsonify(macron.rag.index_file(path))

@app.route("/api/rag/search", methods=["POST"])
def api_rag_search():
    query = request.form.get("query")
    return jsonify(macron.rag.search(query))

@app.route("/api/rag/delete")
def api_rag_delete():
    path = request.args.get("path")
    return jsonify({"deleted": macron.rag.delete_index(path)})

@app.route("/api/planning/create", methods=["POST"])
def api_plan_create():
    name = request.form.get("name")
    desc = request.form.get("desc", "")
    steps = request.form.get("steps", "").strip().split("\n")
    return jsonify(macron.planning.create(name, desc, steps))

@app.route("/api/rutinas/create", methods=["POST"])
def api_rutina_create():
    name = request.form.get("name")
    desc = request.form.get("desc", "")
    cron = request.form.get("cron")
    atype = request.form.get("type")
    params = json.loads(request.form.get("params", "{}"))
    return jsonify(macron.rutinas.create(name, desc, cron, atype, params))

@app.route("/api/vault/setup", methods=["POST"])
def api_vault_setup():
    return jsonify(macron.vault.setup(request.form.get("pwd")))

@app.route("/api/vault/store", methods=["POST"])
def api_vault_store():
    return jsonify(macron.vault.store(request.form.get("key"), request.form.get("value"), request.form.get("pwd")))

@app.route("/api/vault/retrieve", methods=["POST"])
def api_vault_retrieve():
    return jsonify(macron.vault.retrieve(request.form.get("key"), request.form.get("pwd")))

if __name__ == "__main__":
    print("=" * 50)
    print("  MACRON Web UI v2.1")
    print("  http://localhost:5000")
    print("=" * 50)
    app.run(host="0.0.0.0", port=5001, debug=False)
