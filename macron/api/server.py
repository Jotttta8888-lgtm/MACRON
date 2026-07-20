"""
macron/api/server.py
API Flask para MACRON v3.0 con auth + cache + threading
"""
import os
import json
import threading
import time
from flask import Flask, render_template, request, jsonify, Response
from flask_cors import CORS
from concurrent.futures import ThreadPoolExecutor
from flask_sock import Sock
from .auth import require_auth, auth_status

def create_app():
    app = Flask(__name__,
                template_folder=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'ui', 'templates'),
                static_folder=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'ui', 'static'))
    CORS(app)
    sock = Sock(app)
    _api_cache = {}
    _cache_ttl = 10
    executor = ThreadPoolExecutor(max_workers=4)
    
    try:
        from macron.core.engine import get_engine
        engine = get_engine()
    except Exception as e:
        engine = None
        print(f"[SERVER] Engine no disponible: {e}")
    
    def get_module_status_html():
        if not engine:
            return '<span class="chip off">Engine no iniciado</span>'
        try:
            status = engine.status()
            modules = []
            for name in status.get('modules', []):
                modules.append(f'<span class="chip on"><span class="status-dot on"></span>{name}</span>')
            return "\n".join(modules) if modules else '<span class="chip off">Cargando...</span>'
        except Exception as e:
            return f'<span class="chip off">Error: {e}</span>'
    
    def _cached_response(key, getter_func):
        now = time.time()
        if key in _api_cache:
            value, timestamp = _api_cache[key]
            if now - timestamp < _cache_ttl:
                return value
        value = getter_func()
        _api_cache[key] = (value, now)
        return value

    @app.route('/')
    def home():
        return render_template('index.html', modules_html=get_module_status_html())
    
    @app.route('/api/auth/status')
    def auth_info():
        return jsonify(auth_status())
    
    @app.route('/api/status')
    @require_auth
    def status():
        if not engine:
            return jsonify({'error': 'Engine no disponible', 'healthy': False}), 500
        try:
            h = engine.health()
            return jsonify({**h, 'hardware': {'apple_silicon': True, 'neural_engine': True, 'second_brain': 'FAISS', 'architecture': 'Dual Brain v3.0'}})
        except Exception as e:
            return jsonify({'error': str(e), 'healthy': False}), 500
    
    @app.route('/api/chat', methods=['POST'])
    @require_auth
    def chat():
        data = request.get_json()
        message = data.get('message', '')
        try:
            if not engine:
                return jsonify({'error': 'Engine no disponible'}), 500
            agent = engine.registry.get("conversation")
            if agent and hasattr(agent, 'generate_response'):
                result = agent.generate_response(message)
                return jsonify({'text': result.get('text', ''), 'sentiment': result.get('sentiment', '')})
            return jsonify({'error': 'ConversationAgent no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    def _threaded_endpoint(adapter_name, method_name, cache_key, **kwargs):
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get(adapter_name)
                if adapter and hasattr(adapter, method_name):
                    result = getattr(adapter, method_name)(**kwargs)
                    return {'result': result}, 200
                return {'error': f'{adapter_name} no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @app.route('/api/safari/tabs')
    @require_auth
    def safari_tabs():
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get("safari")
                if adapter and hasattr(adapter, 'get_tabs'):
                    tabs = adapter.get_tabs()
                    return {'tabs': tabs, 'active': adapter.get_active_tab(), 'count': len(tabs)}, 200
                return {'error': 'SafariAdapter no disponible'}, 404
        return _cached_response('safari_tabs', lambda: _threaded_endpoint("safari", "get_tabs", "safari_tabs"))
    
    @app.route('/api/mail/inbox')
    @require_auth
    def mail_inbox():
        limit = request.args.get('limit', 10, type=int)
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get("mail")
                if adapter and hasattr(adapter, 'get_inbox'):
                    emails = adapter.get_inbox(limit)
                    return {'emails': emails, 'count': len(emails)}, 200
                return {'error': 'MailAdapter no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @app.route('/api/finder/desktop')
    @require_auth
    def finder_desktop():
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get("finder")
                if adapter and hasattr(adapter, 'get_desktop_files'):
                    files = adapter.get_desktop_files()
                    return {'files': files, 'count': len(files)}, 200
                return {'error': 'FinderAdapter no disponible'}, 404
        return _cached_response('finder_desktop', lambda: (lambda: (future := executor.submit(_get), future.result(timeout=15))[1])())
    
    @app.route('/api/calendar/today')
    @require_auth
    def calendar_today():
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get("calendar")
                if adapter and hasattr(adapter, 'get_today_events'):
                    events = adapter.get_today_events()
                    return {'events': events, 'count': len(events)}, 200
                return {'error': 'CalendarAdapter no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @app.route('/api/notes/list')
    @require_auth
    def notes_list():
        limit = request.args.get('limit', 10, type=int)
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get("notes")
                if adapter and hasattr(adapter, 'get_notes'):
                    notes = adapter.get_notes(limit)
                    return {'notes': notes, 'count': len(notes)}, 200
                return {'error': 'NotesAdapter no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @app.route('/api/reminders/pending')
    @require_auth
    def reminders_pending():
        list_name = request.args.get('list', 'Recordatorios')
        limit = request.args.get('limit', 10, type=int)
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                adapter = engine.registry.get("reminders")
                if adapter and hasattr(adapter, 'get_reminders'):
                    rems = adapter.get_reminders(list_name, completed=False, limit=limit)
                    return {'reminders': rems, 'count': len(rems)}, 200
                return {'error': 'RemindersAdapter no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @app.route('/api/agent/summary')
    @require_auth
    def agent_summary():
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                agent = engine.registry.get("productivity")
                if agent and hasattr(agent, 'daily_summary'):
                    return agent.daily_summary(), 200
                return {'error': 'ProductivityAgent no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @app.route('/api/monitor/report')
    @require_auth
    def monitor_report():
        def _get():
            with app.app_context():
                if not engine: return {'error': 'Engine no disponible'}, 500
                agent = engine.registry.get("monitor")
                if agent and hasattr(agent, 'full_report'):
                    return agent.full_report(), 200
                return {'error': 'MonitorAgent no disponible'}, 404
        future = executor.submit(_get)
        data, status = future.result(timeout=15)
        return jsonify(data), status
    
    @sock.route('/ws/chat')
    def ws_chat(ws):
        """WebSocket para chat en tiempo real."""
        while True:
            try:
                message = ws.receive()
                if not message:
                    break
                if not engine:
                    ws.send(json.dumps({'error': 'Engine no disponible'}))
                    continue
                agent = engine.registry.get("conversation")
                if agent and hasattr(agent, 'generate_response'):
                    result = agent.generate_response(message)
                    ws.send(json.dumps({
                        'text': result.get('text', ''),
                        'sentiment': result.get('sentiment', ''),
                        'timestamp': result.get('timestamp', '')
                    }))
                else:
                    ws.send(json.dumps({'error': 'ConversationAgent no disponible'}))
            except Exception as e:
                ws.send(json.dumps({'error': str(e)}))
                break

    @app.route('/api/stream')
    @require_auth
    def stream():
        """Server-Sent Events para notificaciones en tiempo real."""
        def event_stream():
            import time
            last_check = time.time()
            while True:
                time.sleep(5)
                now = time.time()
                data = {'timestamp': now, 'type': 'heartbeat', 'healthy': True}
                
                # Verificar mails no leidos
                try:
                    if engine:
                        mail = engine.registry.get("mail")
                        if mail:
                            unread = mail.get_unread_count()
                            if unread > 0:
                                data['notification'] = {
                                    'type': 'mail',
                                    'message': f'Tienes {unread} mails no leidos',
                                    'count': unread
                                }
                except:
                    pass
                
                yield f"data: {json.dumps(data)}\n\n"
        
        return Response(event_stream(), mimetype='text/event-stream')

    return app

if __name__ == '__main__':
    app = create_app()
    print('='*50)
    print('  MACRON API v3.0 - http://localhost:5000')
    print('  Auth: X-API-Key header required')
    print('  Cache: 10s TTL | Threading: 4 workers')
    print('='*50)
    app.run(host='0.0.0.0', port=5000, debug=False)
