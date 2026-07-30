# ROADMAP MACRON — Mejoras Futuras

## Fase 8.5 — Voice Clone REAL (Pendiente)
Estado: Voice Profile basico implementado (pitch + rate). Voice Clone real requiere modelo de IA.

Tecnologias a evaluar:
- Coqui XTTS v2 (~3-4 GB, mejor calidad, requiere Python + PyTorch)
- StyleTTS 2 (~1-2 GB, buena calidad, requiere Python)
- RVC (~500 MB, requiere Python)
- CoreML conversion (complejo, tamano variable)

Arquitectura propuesta:
Usuario habla -> MACRON (Swift) graba muestras
-> Servidor Python local (Coqui XTTS) via HTTP
-> Genera audio con voz clonada
-> MACRON reproduce el audio generado

Requisitos:
- Python 3.10+ con PyTorch
- ~4 GB espacio en disco
- GPU preferida (Apple Silicon Metal funciona)
- Tiempo estimado: 6-8 horas de implementacion

---

## Fase 9 — Meeting Recorder (Pendiente)
Feature: Graba Zoom/Teams + transcribe + resume con LLM
Tecnologia: Screen capture + Whisper local + LLM resumen
Tiempo estimado: 4-5 horas

---

## Fase 10 — Plugin Marketplace (Pendiente)
Feature: Sistema de plugins para que terceros extiendan MACRON
Tecnologia: Swift Package Manager + sandboxed plugins
Tiempo estimado: 1-2 dias

---

## Fase 11 — HomeKit Hub (Pendiente)
Feature: Apaga las luces — controla luces, termostatos, cerraduras
Tecnologia: HomeKit framework nativo de Apple
Tiempo estimado: 2-3 horas

---

## Fase 12 — Smart File Organizer con IA (Pendiente)
Feature: Organiza mi escritorio clasifica archivos por contenido
Tecnologia: Vision + NLP local
Tiempo estimado: 2-3 horas

---

## Fase 13 — Face ID / Biometricos Avanzados (Pendiente)
Feature: Desbloqueo con Face ID, reconocimiento de usuario
Tecnologia: LocalAuthentication + Vision
Tiempo estimado: 3-4 horas

---

## Fase 14 — Multi-idioma Avanzado (Pendiente)
Feature: Traduccion en tiempo real, switch de idioma por voz
Tecnologia: AITranslatorPro + Whisper
Tiempo estimado: 2-3 horas

---

## Mejoras Tecnicas Pendientes
- Migrar a Swift 6 (strict concurrency)
- Tests unitarios automatizados
- CI/CD con GitHub Actions para builds
- Notarizacion de .app para distribucion sin warnings
- Auto-updater integrado (Sparkle framework)
- Modo headless (sin UI, solo CLI/voz)

---

## Bugs Conocidos
- [x] Router de apps no verificaba existencia antes de abrir -> FIXED v4.9.1
- [x] Screen OCR no detectaba variaciones de lea -> FIXED v4.9.2
- [x] Calendario con errores de compilacion -> FIXED v4.9.3
- [ ] Voice Clone: efecto de pitch es sutil, no un clon real
- [ ] Permisos de microfono se piden repetidamente tras recompilar

---

Ultima actualizacion: 2026-07-30
Version actual: v4.9.4 (170 features)
