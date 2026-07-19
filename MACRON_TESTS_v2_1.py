#!/usr/bin/env python3
"""
MACRON Tests v2.1
=================
Suite completa de pruebas para todas las funcionalidades.
Ejecutar: python -m pytest MACRON_TESTS_v2.1.py -v
"""

import pytest
import os, sys, json, tempfile, time
from pathlib import Path

# Add parent dir to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from MACRON_FUNCIONALIDADES_v2 import (
    MacronConfig, MacronRAG, MacronPlanning, MacronCoT,
    MacronRutinas, MacronFaceRec, MacronNotion, MacronMultiDevice,
    MacronIntrusion, MacronVault, MacronTranscription, MacronCodeCompletion,
    MacronOrchestrator
)

# Fixtures
@pytest.fixture(scope="module")
def orch():
    """Orquestador para tests."""
    return MacronOrchestrator()

@pytest.fixture
def tmp_file():
    """Archivo temporal para tests."""
    f = tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False)
    f.write("Este es un documento de prueba para MACRON.\nContiene informacion sobre el proyecto.\n" * 10)
    f.close()
    yield f.name
    os.unlink(f.name)


# ============================================================
# TESTS CONFIGURACION
# ============================================================

class TestConfig:
    def test_dirs_created(self):
        MacronConfig.ensure_dirs()
        assert MacronConfig.BASE_DIR.exists()
        assert MacronConfig.DATA_DIR.exists()

    def test_db_exists(self):
        assert MacronConfig.db_path().exists()

    def test_model_size(self):
        size = MacronConfig.get_model_size()
        assert size in ("1.5B", "7B", "30B")


# ============================================================
# TESTS RAG
# ============================================================

class TestRAG:
    def test_index_file(self, tmp_file):
        rag = MacronRAG()
        result = rag.index_file(tmp_file)
        assert result["success"] is True
        assert result["chunks"] > 0

    def test_search(self, tmp_file):
        rag = MacronRAG()
        rag.index_file(tmp_file)
        results = rag.search("documento de prueba")
        assert len(results) > 0
        assert "text" in results[0]

    def test_list_indexed(self, tmp_file):
        rag = MacronRAG()
        rag.index_file(tmp_file)
        files = rag.list_indexed()
        assert tmp_file in files

    def test_delete_index(self, tmp_file):
        rag = MacronRAG()
        rag.index_file(tmp_file)
        assert rag.delete_index(tmp_file) is True
        assert tmp_file not in rag.list_indexed()


# ============================================================
# TESTS PLANNING
# ============================================================

class TestPlanning:
    def test_create_plan(self):
        p = MacronPlanning()
        r = p.create("Test Plan", "Descripcion", ["Paso 1", "Paso 2", "Paso 3"])
        assert r["success"] is True
        assert r["steps"] == 3

    def test_get_plan(self):
        p = MacronPlanning()
        r = p.create("Get Test", "Desc", ["A", "B"])
        plan = p.get(r["plan_id"])
        assert plan is not None
        assert plan["name"] == "Get Test"

    def test_update_step(self):
        p = MacronPlanning()
        r = p.create("Update Test", "Desc", ["S1", "S2"])
        assert p.update_step(r["plan_id"], 1, "completed", "Hecho") is True
        plan = p.get(r["plan_id"])
        assert plan["steps"][0]["status"] == "completed"

    def test_delete_plan(self):
        p = MacronPlanning()
        r = p.create("Delete Test", "Desc", ["X"])
        assert p.delete(r["plan_id"]) is True
        assert p.get(r["plan_id"]) is None


# ============================================================
# TESTS CHAIN-OF-THOUGHT
# ============================================================

class TestCoT:
    def test_start_session(self):
        cot = MacronCoT()
        sid = cot.start("Test CoT")
        assert len(sid) > 0

    def test_add_step(self):
        cot = MacronCoT()
        sid = cot.start("Test Steps")
        assert cot.add_step(sid, "analysis", "Analizando...", "razonamiento", 0.9) is True

    def test_get_session(self):
        cot = MacronCoT()
        sid = cot.start("Test Get")
        cot.add_step(sid, "test", "contenido")
        s = cot.get(sid)
        assert s is not None
        assert len(s["steps"]) == 1

    def test_conclude(self):
        cot = MacronCoT()
        sid = cot.start("Test Conclude")
        assert cot.conclude(sid, "Conclusion final") is True
        s = cot.get(sid)
        assert s["conclusion"] == "Conclusion final"

    def test_export_md(self):
        cot = MacronCoT()
        sid = cot.start("Test Export")
        cot.add_step(sid, "step", "content")
        cot.conclude(sid, "done")
        md = cot.export_md(sid)
        assert "Test Export" in md
        assert "done" in md


# ============================================================
# TESTS RUTINAS
# ============================================================

class TestRutinas:
    def test_create_rutina(self):
        r = MacronRutinas()
        result = r.create("Test Rutina", "Desc", "0 * * * *", "shell", {"command": "echo test"})
        assert result["success"] is True

    def test_list_rutinas(self):
        r = MacronRutinas()
        r.create("List Test", "Desc", "0 * * * *", "shell", {})
        rutinas = r.list()
        assert len(rutinas) > 0

    def test_toggle(self):
        r = MacronRutinas()
        res = r.create("Toggle Test", "Desc", "0 * * * *", "shell", {})
        assert r.toggle(res["id"], False) is True

    def test_run_now(self):
        r = MacronRutinas()
        res = r.create("Run Test", "Desc", "0 * * * *", "shell", {"command": "echo hello"})
        result = r.run_now(res["id"])
        assert result["success"] is True


# ============================================================
# TESTS VAULT
# ============================================================

class TestVault:
    def test_setup(self):
        v = MacronVault()
        r = v.setup("test_password_123")
        assert r["success"] is True

    def test_store_retrieve(self):
        v = MacronVault()
        v.setup("test_password_123")
        v.store("api_key", "secret123", "test_password_123")
        r = v.retrieve("api_key", "test_password_123")
        assert r["success"] is True
        assert r["value"] == "secret123"

    def test_wrong_password(self):
        v = MacronVault()
        v.setup("test_password_123")
        r = v.retrieve("api_key", "wrong_password")
        assert r["success"] is False

    def test_list_keys(self):
        v = MacronVault()
        v.setup("test_password_123")
        v.store("key1", "val1", "test_password_123")
        v.store("key2", "val2", "test_password_123")
        keys = v.list_keys("test_password_123")
        assert "key1" in keys
        assert "key2" in keys


# ============================================================
# TESTS MULTI-DISPOSITIVO
# ============================================================

class TestMultiDevice:
    def test_register(self):
        m = MacronMultiDevice("TestMac")
        r = m.register()
        assert r["success"] is True
        assert r["name"] == "TestMac"

    def test_list_devices(self):
        m = MacronMultiDevice("TestMac2")
        m.register()
        devs = m.list_devices()
        assert len(devs) > 0

    def test_sync_memory(self):
        m = MacronMultiDevice("TestMac3")
        m.register()
        r = m.sync_memory()
        assert r["success"] is True
        assert "file" in r


# ============================================================
# TESTS ORQUESTADOR
# ============================================================

class TestOrchestrator:
    def test_init(self, orch):
        assert orch is not None

    def test_status(self, orch):
        s = orch.status()
        assert "version" in s
        assert "hardware" in s
        assert "modules" in s

    def test_notify(self, orch):
        # Solo verifica que no crashea
        orch.log("INFO", "Test message")


# ============================================================
# TESTS INTEGRACION
# ============================================================

class TestIntegration:
    def test_planning_with_cot(self):
        """Planificacion + Chain-of-Thought."""
        p = MacronPlanning()
        cot = MacronCoT()

        plan = p.create("Integ Test", "Test", ["Analizar", "Ejecutar", "Verificar"])
        sid = cot.start("Razonamiento del plan")
        cot.add_step(sid, "planning", f"Plan creado: {plan['plan_id']}")
        cot.conclude(sid, "Plan listo para ejecutar")

        assert p.get(plan["plan_id"]) is not None
        assert cot.get(sid) is not None

    def test_vault_with_rutinas(self):
        """Vault + Rutinas (almacenar credenciales para rutinas)."""
        v = MacronVault()
        r = MacronRutinas()

        v.setup("master_pwd")
        v.store("notion_token", "ntn_12345", "master_pwd")

        rut = r.create("Notion Sync", "Sync con Notion", "0 */6 * * *", "python",
                      {"code": "print('Syncing Notion...)"})
        assert rut["success"] is True


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
