"""
macron/api/server.py
API Flask para MACRON v3.0
"""
import os
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS

def create_app():
    app = Flask(__name__,
                template_folder=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'ui', 'templates'),
                static_folder=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'ui', 'static'))
    CORS(app)
    
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
    
    @app.route('/')
    def home():
        return render_template('index.html', modules_html=get_module_status_html())
    
    @app.route('/api/status')
    def status():
        if not engine:
            return jsonify({'error': 'Engine no disponible', 'healthy': False}), 500
        try:
            h = engine.health()
            return jsonify({**h, 'hardware': {'apple_silicon': True, 'neural_engine': True, 'second_brain': 'FAISS', 'architecture': 'Dual Brain v3.0'}})
        except Exception as e:
            return jsonify({'error': str(e), 'healthy': False}), 500
    
    @app.route('/api/chat', methods=['POST'])
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
    
    @app.route('/api/safari/tabs')
    def safari_tabs():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            adapter = engine.registry.get("safari")
            if adapter and hasattr(adapter, 'get_tabs'):
                tabs = adapter.get_tabs()
                return jsonify({'tabs': tabs, 'active': adapter.get_active_tab(), 'count': len(tabs)})
            return jsonify({'error': 'SafariAdapter no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/mail/inbox')
    def mail_inbox():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            adapter = engine.registry.get("mail")
            if adapter and hasattr(adapter, 'get_inbox'):
                limit = request.args.get('limit', 10, type=int)
                emails = adapter.get_inbox(limit)
                return jsonify({'emails': emails, 'count': len(emails)})
            return jsonify({'error': 'MailAdapter no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/finder/desktop')
    def finder_desktop():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            adapter = engine.registry.get("finder")
            if adapter and hasattr(adapter, 'get_desktop_files'):
                files = adapter.get_desktop_files()
                return jsonify({'files': files, 'count': len(files)})
            return jsonify({'error': 'FinderAdapter no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/calendar/today')
    def calendar_today():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            adapter = engine.registry.get("calendar")
            if adapter and hasattr(adapter, 'get_today_events'):
                events = adapter.get_today_events()
                return jsonify({'events': events, 'count': len(events)})
            return jsonify({'error': 'CalendarAdapter no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/notes/list')
    def notes_list():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            adapter = engine.registry.get("notes")
            if adapter and hasattr(adapter, 'get_notes'):
                limit = request.args.get('limit', 10, type=int)
                notes = adapter.get_notes(limit)
                return jsonify({'notes': notes, 'count': len(notes)})
            return jsonify({'error': 'NotesAdapter no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/reminders/pending')
    def reminders_pending():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            adapter = engine.registry.get("reminders")
            if adapter and hasattr(adapter, 'get_reminders'):
                list_name = request.args.get('list', 'Recordatorios')
                limit = request.args.get('limit', 10, type=int)
                rems = adapter.get_reminders(list_name, completed=False, limit=limit)
                return jsonify({'reminders': rems, 'count': len(rems)})
            return jsonify({'error': 'RemindersAdapter no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/agent/summary')
    def agent_summary():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            agent = engine.registry.get("productivity")
            if agent and hasattr(agent, 'daily_summary'):
                return jsonify(agent.daily_summary())
            return jsonify({'error': 'ProductivityAgent no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    @app.route('/api/monitor/report')
    def monitor_report():
        try:
            if not engine: return jsonify({'error': 'Engine no disponible'}), 500
            agent = engine.registry.get("monitor")
            if agent and hasattr(agent, 'full_report'):
                return jsonify(agent.full_report())
            return jsonify({'error': 'MonitorAgent no disponible'}), 404
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    return app

if __name__ == '__main__':
    app = create_app()
    print('='*50)
    print('  MACRON API v3.0 - http://localhost:5000')
    print('  Dual Brain Architecture')
    print('='*50)
    app.run(host='0.0.0.0', port=5000, debug=False)
