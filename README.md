# MACRON

> The Ultimate Local AI Agent for macOS
> 100% Offline | Apple Silicon Native | 155 Features | SwiftUI Interface | LLM Local

## What is MACRON?

MACRON is a local-first AI agent for macOS that runs entirely on your Mac.
No cloud dependencies, no data leaks, no subscriptions.

- Privacy First: Zero data leaves your Mac
- Apple Silicon Optimized: Built for M1/M2/M3/M4 (Mac NEO)
- 100% Local: LLM, OCR, Speech, Vision -- everything local
- Voice First: Hey Macron wake word + continuous transcription
- Context Aware: Knows what app you are using, what text is selected
- LLM Connected: Ollama/llama.cpp/MLX integration ready

---

## Quick Start (LLM)

1. Install Ollama: `curl -fsSL https://ollama.com/install.sh | sh`
2. Pull model: `ollama pull llama3.2`
3. Launch MACRON.app
4. Say "Hey Macron" and ask anything

---

## Feature Inventory (155 Total)

### Core AI (10)
| Code | Feature | Description |
|------|---------|-------------|
| A | Voice Actions | Execute commands via voice |
| B | Hotkey Pro | Global shortcuts (Cmd+Shift+M) |
| C | TextToSpeech | Premium voice synthesis |
| D | Dictation | Real-time speech-to-text |
| E | Persistent Chat | Conversation history |
| F | Local LLM | On-device language model |
| G | AI Vision | Image analysis & OCR |
| H | AI Personas | Adaptive personality modes |
| I | Smart Notes | Auto-categorized notes |
| J | Productivity Tracker | Usage analytics |

### Advanced Voice (3)
| Code | Feature | Description |
|------|---------|-------------|
| EZ | VoiceContextEngine | Reads active app, window, selected text |
| FA | RealtimeTranscriber | Continuous offline transcription + VAD |
| FD | VoiceBiometrics | Voiceprint authentication (MFCC) |

### Intelligence (4)
| Code | Feature | Description |
|------|---------|-------------|
| FB | AgentOrchestrator | 7 tools: open_app, open_url, write_note, run_shell, set_reminder, get_context, search_spotlight |
| FC | ReasoningEngine | Chain-of-Thought reasoning |
| FE | ProactiveAI | Smart interruptions: breaks, hydration, focus |
| Brain | MACRONBrain | Central orchestrator with LLMConnector |

### v4.6.0 AI Features (10)
| Code | Feature | Description |
|------|---------|-------------|
| FF | SmartHomeAI | HomeKit control via Shortcuts/AppleScript |
| FG | ScreenReaderAI | Reads selected text with premium voice |
| FH | CodeAssistant | Error explanations, snippets, refactoring |
| FI | SmartScheduler | Voice-scheduled meetings with Calendar |
| FJ | DocumentAI | PDF Q&A, summarization, table extraction |
| FK | ScreenCaptureAI | Screenshot + OCR (ScreenCaptureKit) |
| FL | EmailDraftAI | Voice-dictated emails with templates |
| FM | WindowManagerAI | Smart tiling: focus mode, grid, maximize |
| FN | ClipboardAI | Smart clipboard with type detection |
| FO | QuickTranslate | Detect language + translate selection |

### v4.7.0 Features (5)
| Code | Feature | Description |
|------|---------|-------------|
| FP | LLMConnector | Connects to Ollama/llama.cpp/MLX local LLM |
| FQ | VoiceprintTrainerUI | SwiftUI interface to record and train voiceprint |
| FR | FocusSessionsPro | Advanced Pomodoro: blocks distractions, DND, reports |
| FT | SystemDiagnostics | Mac health: CPU, RAM, disk, processes, recommendations |
| FS | SmartSearch | Universal search: apps, files, notes, commands, web |

...and 124 more features covering:
- Security (Touch ID, Vault, VPN, Password Manager)
- Finance (Tracker, Stocks)
- Entertainment (Music, Podcasts, Game Mode)
- Weather Advisor
- Network Monitor & WiFi Analyzer
- Terminal Emulator, Python REPL, Local Web Server
- Markdown Editor, Spreadsheet AI
- Wellbeing (Breathing, Sleep, Journal)
- Offline Maps & Travel Planner
- Recipe Manager & Package Tracker

---

## Architecture

    +---------------------------------------------+
    |           MACRON v4.7.1 Brain               |
    +---------------------------------------------+
    |  LLMConnector (FP) -> Ollama/llama.cpp     |
    |  VoiceContextEngine (EZ)                    |
    |  RealtimeTranscriber (FA)                   |
    |  AgentOrchestrator (FB)                     |
    |  ReasoningEngine (FC)                       |
    |  VoiceBiometrics (FD)                       |
    |  ProactiveAI (FE)                           |
    +---------------------------------------------+
    |  SmartHomeAI (FF)                           |
    |  ScreenReaderAI (FG)                        |
    |  CodeAssistant (FH)                         |
    |  SmartScheduler (FI)                        |
    |  DocumentAI (FJ)                            |
    |  ScreenCaptureAI (FK)                       |
    |  EmailDraftAI (FL)                          |
    |  WindowManagerAI (FM)                       |
    |  ClipboardAI (FN)                           |
    |  QuickTranslate (FO)                        |
    |  VoiceprintTrainerUI (FQ)                   |
    |  FocusSessionsPro (FR)                      |
    |  SystemDiagnostics (FT)                     |
    |  SmartSearch (FS)                           |
    +---------------------------------------------+
    |  SwiftUI Native Interface                   |
    |     - Dashboard                             |
    |     - Chat                                  |
    |     - Feature Grid (155)                    |
    |     - Tools Panel                           |
    |     - Settings                              |
    +---------------------------------------------+

---

## Installation

### Option 1: Download DMG
1. Download MACRON_v4.7.1_155features_LLM.dmg from Releases
2. Open DMG, drag MACRON.app to Applications
3. Launch and grant permissions

### Option 2: Build from Source
    git clone https://github.com/Jotttta8888-lgtm/MACRON.git
    cd MACRON/MACRON_v4
    swift build -c release

### Option 3: Connect LLM (Ollama)
    # 1. Install Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    
    # 2. Download model (3B params, ~2GB)
    ollama pull llama3.2
    
    # 3. Start server (auto-starts with MACRON)
    ollama serve
    
    # 4. MACRON will auto-detect localhost:11434

---

## Required Permissions

After first launch, grant these in System Settings > Privacy & Security:

| Permission | Why |
|------------|-----|
| Accessibility | Window management, context reading |
| Microphone | Voice commands & transcription |
| Speech Recognition | Local dictation |
| Calendar | Smart scheduling |
| Camera | Screen capture for OCR |
| HomeKit | Smart home control |
| Automation | AppleScript app control |

---

## Voice Commands

Say "Hey Macron" followed by:

| Command | Action |
|---------|--------|
| "Abre Safari" | Opens Safari |
| "Modo focus" | Tiles windows for productivity |
| "Reunete con Maria manana a las 3" | Schedules meeting |
| "Leeme esto" | Reads selected text |
| "Traduce esto" | Translates selection to Spanish |
| "Modo cine" | Activates HomeKit scene |
| "Escribe un email a Juan" | Drafts email in Mail.app |
| "Cuanto cuesta esto" | OCR + price detection |
| "Resume este PDF" | Document analysis |
| "Snippet singleton" | Copies code snippet |
| "Diagnostico del sistema" | Shows CPU/RAM/disk health |
| "Inicia focus session" | Blocks distractions for 25 min |
| "Busca archivo reporte" | Universal search across Mac |

---

## Developer Setup

### Connect Your LLM
MACRONBrain.swift now uses LLMConnector automatically. To switch providers:

    LLMConnector.shared.provider = .ollama      // Default
    LLMConnector.shared.provider = .llamaCPP   // llama.cpp server
    LLMConnector.shared.provider = .custom       // Your endpoint

### Train Voice Biometrics
Open VoiceprintTrainerUI from Settings > Security, press Record, and speak for 5 seconds.

---

## Stats

- Lines of Code: ~18,000+
- Swift Files: 168
- Frameworks: AppKit, SwiftUI, Vision, Speech, NaturalLanguage, EventKit, ScreenCaptureKit, AVFoundation, Accelerate, HomeKit
- Build Time: ~10s debug, ~72s release
- Binary Size: 3.3MB
- DMG Size: 1.2MB

---

## Roadmap

- [x] 150 Features (v4.6.1)
- [x] 155 Features + LLM Local (v4.7.1)
- [ ] 160+ Features (v4.8.0)
- [ ] macOS 27 Golden Gate integration
- [ ] Apple Intelligence framework migration
- [ ] Plugin marketplace
- [ ] iOS companion app

---

## Contributing

Personal project by Jotttta8888-lgtm. Built with care on a Mac NEO.

---

## License

MIT License - feel free to fork, modify, and distribute.

> MACRON does not just respond. It understands, reasons, and acts -- all on your Mac.
