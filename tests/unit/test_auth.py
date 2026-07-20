"""
tests/unit/test_auth.py
Tests para autenticación API
"""
import pytest
from macron.api.auth import get_api_key, auth_status

class TestAuth:
    def test_api_key_exists(self):
        key = get_api_key()
        assert len(key) > 20
    
    def test_auth_status(self):
        status = auth_status()
        assert status['enabled'] is True
        assert 'key_prefix' in status
