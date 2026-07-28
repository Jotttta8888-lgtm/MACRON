# MACRON

> The Ultimate Local AI Agent for macOS
> 100% Offline | Apple Silicon Native | 150 Features | SwiftUI Interface

## What is MACRON?

MACRON is a local-first AI agent for macOS that runs entirely on your Mac.
No cloud dependencies, no data leaks, no subscriptions.

- Privacy First: Zero data leaves your Mac
- Apple Silicon Optimized: Built for M1/M2/M3/M4 (Mac NEO)
- 100% Local: LLM, OCR, Speech, Vision -- everything local
- Voice First: Hey Macron wake word + continuous transcription
- Context Aware: Knows what app you are using, what text is selected

## Feature Inventory (150 Total)

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
| Brain | MACRONBrain | Central orchestrator |

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

...and 124 more features.

## Architecture

    +---------------------------------------------+
    |           MACRON v4.6.1 Brain               |
    +---------------------------------------------+
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
    +---------------------------------------------+
    |  SwiftUI Native Interface                   |
    |     - Dashboard                             |
    |     - Chat                                  |
    |     - Feature Grid (150)                    |
    |     - Tools Panel                           |
    |     - Settings                              |
    +---------------------------------------------+

## Installation

### Option 1: Download DMG
1. Download MACRON_v4.6.1_150features.dmg from Releases
2. Open DMG, drag MACRON.app to Applications
3. Launch and grant permissions

### Option 2: Build from Source
    git clone https://github.com/Jotttta8888-lgtm/MACRON.git
    cd MACRON/MACRON_v4
    swift build -c release

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

## Voice Commands

Say Hey Macron followed by:

| Command | Action |
|---------|--------|
| Abre Safari | Opens Safari |
| Modo focus | Tiles windows for productivity |
| Reunete con Maria manana a las 3 | Schedules meeting |
| Leeme esto | Reads selected text |
| Traduce esto | Translates selection to Spanish |
| Modo cine | Activates HomeKit scene |
| Escribe un email a Juan | Drafts email in Mail.app |
| Cuanto cuesta esto | OCR + price detection |
| Resume este PDF | Document analysis |
| Snippet singleton | Copies code snippet |

## Developer Setup

Connect Your LLM in MACRONBrain.swift:

    private func generateLLMResponse(_ prompt: String) async -> String {
        return await LLMService.shared.generate(
            prompt: prompt,
            context: contextEngine.currentContext
        )
    }

Train Voice Biometrics:

    VoiceBiometrics.shared.train(with: audioBuffer) { success in
        print("Voiceprint trained: \(success)")
    }

## Stats

- Lines of Code: ~15,000+
- Swift Files: 163
- Frameworks: AppKit, SwiftUI, Vision, Speech, NaturalLanguage, EventKit, ScreenCaptureKit, AVFoundation
- Build Time: ~10s debug, ~72s release
- Binary Size: 3.2MB
- DMG Size: 1.1MB

## Roadmap

- [x] 150 Features (v4.6.1)
- [ ] 160+ Features (v4.7.0)
- [ ] macOS 27 Golden Gate integration
- [ ] Apple Intelligence framework migration
- [ ] Plugin marketplace
- [ ] iOS companion app

## Contributing

Personal project by Jotttta8888-lgtm. Built with care on a Mac NEO.

## License

MIT License - feel free to fork, modify, and distribute.

> MACRON does not just respond. It understands, reasons, and acts -- all on your Mac.
