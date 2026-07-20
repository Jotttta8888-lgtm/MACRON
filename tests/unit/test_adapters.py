"""
tests/unit/test_adapters.py
Tests unitarios para adapters v3.0
"""
import pytest
from macron.adapters.base import BaseAdapter, AppleScriptResult
from macron.adapters.safari import SafariAdapter
from macron.adapters.finder import FinderAdapter

class MockAdapter(BaseAdapter):
    __macron_module__ = True
    __macron_name__ = "mock"
    def info(self):
        return {}

class TestAppleScriptResult:
    def test_success(self):
        r = AppleScriptResult(stdout="test", stderr="", returncode=0)
        assert r.success is True
        assert r.stdout == "test"
    
    def test_failure(self):
        r = AppleScriptResult(stdout="", stderr="error", returncode=1)
        assert r.success is False

class TestBaseAdapter:
    def test_escape_applescript(self):
        adapter = MockAdapter()
        assert '\\"' in adapter._escape_applescript('test"injection')
        assert '\n' not in adapter._escape_applescript('line1\nline2')
        assert len(adapter._escape_applescript('x' * 6000)) <= 5014

class TestSafariAdapter:
    def test_instantiation(self):
        sa = SafariAdapter()
        assert sa.name == "safari"
        assert sa.version == "3.0"
    
    def test_info(self):
        sa = SafariAdapter()
        info = sa.info()
        assert info['name'] == 'safari'
        assert 'get_tabs' in info['methods']

class TestFinderAdapter:
    def test_instantiation(self):
        fa = FinderAdapter()
        assert fa.name == "finder"
        assert fa.version == "3.0"
    
    def test_human_size(self):
        fa = FinderAdapter()
        assert fa._human_size(1024) == "1.0 KB"
        assert fa._human_size(1024*1024) == "1.0 MB"
