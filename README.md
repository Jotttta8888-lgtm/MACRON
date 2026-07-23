# MACRON - Asistente AI Local para macOS

**Version 3.1** | macOS 15+ | 100% Local & Privado

MACRON es un asistente de inteligencia artificial completamente local para macOS que integra 28 modulos nativos, 5 agentes autonomos y un sistema de plugins extensible. Ningun dato sale de tu Mac.

## Estado del Proyecto

- **Interfaz Python/Tkinter** (estable): `macron_ui_v3.py` + servidor Flask
- **Interfaz SwiftUI** (en desarrollo): `MACRON_v4/` — Swift Package Manager, NativeTextField, dictado nativo macOS

## Caracteristicas Principales

- Navegador: Control de Safari
- Email: Gestion de Mail.app
- Archivos: Interaccion con Finder
- Calendario: Eventos de Calendar.app
- Notas: Crear, buscar y gestionar notas
- Recordatorios: Tareas y alertas
- Agente Productividad: Resumenes diarios
- Agente Monitoreo: Escaneo de carpetas
- Agente Investigacion: Busqueda web
- Sistema de Plugins: Extension dinamica
- Agente Conversacional: Memoria persistente
- Voz: Reconocimiento de voz
- Analytics: Metricas locales
- Encriptacion: Datos protegidos

## Instalacion Rapida

    git clone https://github.com/Jotttta8888-lgtm/MACRON.git
    cd MACRON
    chmod +x install_macron_v3.sh
    ./install_macron_v3.sh

## Uso

- Interfaz Web: http://127.0.0.1:5000
- App .app: Doble clic en MACRON.app
- Atajo: Cmd + Shift + M

## Arquitectura

    MACRON/
    ├── macron_core.py              # Nucleo del sistema
    ├── macron_ui_v3.py             # Interfaz web Python/Tkinter
    ├── macron_agent_*.py           # Agentes autonomos (5)
    ├── macron_plugins.py           # Sistema de plugins
    ├── MACRON_v4/                  # SwiftUI (en desarrollo)
    │   ├── Package.swift
    │   └── Sources/MACRON/
    ├── MACRON.app/                 # App .app nativa
    ├── MACRON_Xcode_Project/       # Proyecto Xcode legacy
    └── plugins/                    # Plugins de terceros

## Compilar SwiftUI (MACRON_v4)

    cd MACRON_v4
    swift build

## Modulos Activos (28/28)

Safari, Mail, Finder, Calendar, Notes, Reminders, Productivity, Monitor, Research, Conversation, Plugin System + 17 mas.

## Sistema de Plugins

Crea plugins en ~/Documents/MACRON/plugins/

## Privacidad

100% local. Ningun dato sale de tu Mac.

## Autor

Juan Camilo - @Jotttta8888-lgtm

## Licencia

MIT License
