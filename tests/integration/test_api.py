"""
tests/integration/test_api.py
Tests de integración para API
"""
import pytest
import os
from macron.api.server import create_app

@pytest.fixture
def client():
    app = create_app()
    with app.test_client() as client:
        yield client

@pytest.fixture
def api_key():
    with open(os.path.expanduser('~/.macron_api_key')) as f:
        return f.read().strip()

class TestAPI:
    def test_home(self, client):
        r = client.get('/')
        assert r.status_code == 200
    
    def test_auth_required(self, client):
        r = client.get('/api/status')
        assert r.status_code == 401
    
    def test_auth_invalid(self, client):
        r = client.get('/api/status', headers={'X-API-Key': 'wrong'})
        assert r.status_code == 403
    
    def test_status(self, client, api_key):
        r = client.get('/api/status', headers={'X-API-Key': api_key})
        assert r.status_code == 200
        data = r.get_json()
        assert 'engine' in data
    
    def test_safari_tabs(self, client, api_key):
        r = client.get('/api/safari/tabs', headers={'X-API-Key': api_key})
        assert r.status_code == 200
        data = r.get_json()
        assert 'tabs' in data
    
    def test_finder_desktop(self, client, api_key):
        r = client.get('/api/finder/desktop', headers={'X-API-Key': api_key})
        assert r.status_code == 200
        data = r.get_json()
        assert 'files' in data
    
    def test_cache(self, client, api_key):
        import time
        t0 = time.time()
        r1 = client.get('/api/finder/desktop', headers={'X-API-Key': api_key})
        t1 = time.time()
        r2 = client.get('/api/finder/desktop', headers={'X-API-Key': api_key})
        t2 = time.time()
        assert r1.status_code == 200
        assert r2.status_code == 200
        assert (t2 - t1) < (t1 - t0)  # Segunda llamada más rápida
