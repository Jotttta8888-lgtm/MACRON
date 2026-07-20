# Guia de Desarrollo MACRON

## Requisitos

- macOS 15+ (Sequoia/Golden Gate)
- Python 3.12+
- Xcode Command Line Tools
- Git

## Entorno de Desarrollo

    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt

## Estructura de Modulos

Cada modulo sigue este patron:

    class ModuloX:
        def __init__(self, core):
            self.core = core
            self.name = "ModuloX"
        
        def metodo_principal(self, args):
            # Logica del modulo
            return {"success": True, "data": result}

## Agregar un Nuevo Modulo al Core

1. Crear archivo: macron_nuevo.py
2. Importar en macron_core.py
3. Agregar a MODULE_STATUS
4. Crear metodos wrapper en MacronCore
5. Agregar endpoint en macron_ui_v3.py
6. Agregar boton en la UI HTML

## Crear un Plugin

Crear archivo en plugins/mi_plugin.py:

    class MiPlugin:
        def __init__(self, core):
            self.core = core
            self.name = "MiPlugin"
        
        def run(self, args=None):
            return {"success": True}
        
        def info(self):
            return {"name": self.name, "version": "1.0"}

    def create_plugin(core):
        return MiPlugin(core)

## Testing

    python3 -m pytest MACRON_TESTS_v2_1.py

## Commit

    git add -A
    git commit -m "Descripcion del cambio"
    git push origin main
