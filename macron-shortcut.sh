#!/bin/bash
# MACRON Siri Shortcut - Envía comando de voz a MACRON API
TEXT="${1:-Hola MACRON}"
curl -s -X POST http://localhost:5001/api/voice-action \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$TEXT\"}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','Listo'))"
