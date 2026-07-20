# Guia de Usuario MACRON

## Primeros Pasos

1. Doble clic en MACRON.app o ejecuta:
   python3 macron_ui_v3.py

2. Abre http://127.0.0.1:5000 en tu navegador

3. Concede permisos de accesibilidad cuando macOS lo solicite

## Funciones Principales

### Chat con MACRON
- Escribe en el campo de texto y presiona Enter
- MACRON recuerda tus conversaciones

### Calendario
- "Crear evento manana a las 3pm: Reunion"
- "Listar eventos de hoy"

### Notas
- "Crear nota: Ideas para el proyecto"
- "Buscar notas con proyecto"

### Safari
- "Buscar en Safari: Python tutorial"
- "Abrir URL: https://apple.com"

### Mail
- "Leer mails no leidos"
- "Enviar mail a juan@ejemplo.com"

### Finder
- "Listar archivos en Descargas"
- "Abrir carpeta Documentos"

### Plugins
- Crea plugins en ~/Documents/MACRON/plugins/
- Recarga desde la interfaz

## Atajos de Teclado

- Cmd + Shift + M: Abrir MACRON
- Cmd + Enter: Enviar mensaje

## Solucion de Problemas

### MACRON no inicia
- Verifica que el entorno virtual este activo
- Revisa macron.log para errores

### Permisos denegados
- Ve a Preferencias del Sistema > Seguridad y Privacidad > Accesibilidad
- Agrega Terminal y tu navegador

### Modulo no responde
- Revisa que la app de macOS este abierta (Safari, Mail, etc.)
- Algunas funciones requieren que la app este en primer plano
