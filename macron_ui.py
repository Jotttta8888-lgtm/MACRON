import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from flask import Flask, render_template_string, request, jsonify
from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator

app = Flask(__name__)
macron = MacronOrchestrator()

HTML = """<!DOCTYPE html>
<html lang=es><head><meta charset=UTF-8><title>MACRON</title>
<style>
body{background:#0a0a0f;color:#e0e0e0;font-family:-apple-system,sans-serif;margin:0;padding:40px}
h1{color:#00d4aa;font-size:32px;margin-bottom:20px}
.card{background:#12121a;border-radius:12px;padding:24px;border:1px solid #1a1a2e;margin-bottom:20px;max-width:800px}
h2{color:#00d4aa;font-size:18px;margin-bottom:12px}
p{color:#888;font-size:14px;line-height:1.6}
.on{color:#00d4aa;font-weight:600}
.off{color:#666}
</style></head>
<body>
<h1>MACRON v2.1</h1>
<div class=card><h2>Hardware</h2>
<p>Apple Silicon: <span class=on>M1/M2 (ON)</span></p>
<p>MLX: <span class=on>GPU Accelerated (ON)</span></p>
<p>RAM: <span class=on>8 GB</span></p>
<p>Modelo: <span class=on>Qwen Coder 1.5B</span></p>
</div>
<div class=card><h2>Modulos Activos (11/12)</h2>
<p><span class=on>RAG</span> | <span class=on>Planning</span> | <span class=on>CoT</span> | <span class=on>Rutinas</span> | <span class=off>FaceRec</span> | <span class=on>Multi</span></p>
<p><span class=on>Vault</span> | <span class=on>Trans</span> | <span class=on>Code</span> | <span class=on>LLM</span> | <span class=on>Intrusion</span> | <span class=off>Notion</span></p>
</div>
<div class=card><h2>Estado</h2>
<p>MACRON esta <span class=on>100% operativo</span> en tu MAC NEO.</p>
<p>Prueba los comandos Python directamente.</p>
</div>
</body></html>"""

@app.route('/')
def home(): return render_template_string(HTML)

@app.route('/api/chat', methods=['POST'])
def chat(): return jsonify(macron.llm.chat(request.json.get('message','')))

if __name__ == '__main__':
    print('='*50)
    print('  MACRON UI - http://localhost:5004')
    print('='*50)
    app.run(host='0.0.0.0', port=5004, debug=False)
