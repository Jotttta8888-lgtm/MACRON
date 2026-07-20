
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import os
import logging

from ..core.engine import get_engine

logger = logging.getLogger(__name__)

def create_app(config=None):
    app = Flask(__name__, static_folder="../../ui/static", template_folder="../../ui/templates")
    CORS(app)
    engine = get_engine()
    @app.route("/api/health")
    def health():
        return jsonify(engine.health())
    @app.route("/api/status")
    def status():
        return jsonify(engine.status())
    @app.route("/api/<module>/<action>", methods=["POST"])
    def adapter_action(module, action):
        data = request.get_json() or {}
        return jsonify(engine.call(module, action, **data))
    @app.route("/api/agents/<agent>/<action>", methods=["POST"])
    def agent_action(agent, action):
        data = request.get_json() or {}
        mod = engine.registry.get(agent)
        if not mod:
            return jsonify({"success": False, "error": f"Agente {agent} no disponible"}), 404
        method = getattr(mod, action, None)
        if not method:
            return jsonify({"success": False, "error": f"Accion {action} no existe"}), 404
        try:
            return jsonify({"success": True, "data": method(**data)})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500
    @app.route("/api/chat", methods=["POST"])
    def chat():
        data = request.get_json() or {}
        message = data.get("message", "")
        agent = engine.registry.get("conversation")
        if agent:
            result = agent.generate_response(message)
            return jsonify(result)
        return jsonify({"text": "Agente no disponible", "error": True})
    @app.route("/api/plugins/list")
    def plugins_list():
        pm = engine.registry.get("plugin_manager")
        if pm:
            return jsonify({"plugins": pm.list_plugins(), "count": len(pm.list_plugins())})
        return jsonify({"plugins": [], "count": 0})
    @app.route("/api/plugins/run", methods=["POST"])
    def plugins_run():
        data = request.get_json() or {}
        pm = engine.registry.get("plugin_manager")
        if pm:
            return jsonify(pm.run_plugin(data.get("name"), data.get("args")))
        return jsonify({"error": "Plugin system no disponible"}), 500
    @app.route("/")
    def index():
        return send_from_directory("../../ui/templates", "index.html")
    @app.route("/static/<path:path>")
    def static_files(path):
        return send_from_directory("../../ui/static", path)
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="127.0.0.1", port=5000, debug=False)
