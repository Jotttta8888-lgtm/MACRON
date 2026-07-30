import Foundation
import EventKit
import AppKit
import Speech
import UserNotifications
import AVFoundation

public final class MACRONBrain: @unchecked Sendable {
    public static let shared = MACRONBrain()
    public let contextEngine = VoiceContextEngine.shared
    public let transcriber = RealtimeTranscriber.shared
    public let orchestrator = AgentOrchestrator.shared
    public let reasoning = ReasoningEngine.shared
    public let biometrics = VoiceBiometrics.shared
    public let proactive = ProactiveAI.shared
    public private(set) var isRunning = false
    public var wakeWord = "Hey Macron", useReasoning = true, useBiometrics = true, useProactive = true
    public var onSystemMessage: ((String) -> Void)?
    public var onUserTranscript: ((String) -> Void)?
    public var onAIResponse: ((String) -> Void)?
    private let synthesizer = AVSpeechSynthesizer()
    private init() { setupTranscriber(); setupNotifications() }
    public func boot() {
        guard !isRunning else { return }
        isRunning = true
        contextEngine.startMonitoring(interval: 2.0)
        transcriber.requestAuthorization { [weak self] g in guard let self = self, g else { return }; self.transcriber.startListening() }
        if useProactive { proactive.startMonitoring() }
        onSystemMessage?("🧠 MACRON Brain activado. Escuchando...")
    }
    public func shutdown() {
        isRunning = false
        contextEngine.stopMonitoring(); transcriber.stopListening(); proactive.stopMonitoring()
        onSystemMessage?("🛑 MACRON Brain detenido.")
    }
    public func processUserMessage(_ text: String, source: MessageSource = .text) async -> String {
        onUserTranscript?(text)
        // Router local para comandos simples (mas rapido y preciso que LLM)
        let lower = text.lowercased()
        
        // Abrir apps
        if lower.contains("abre") || lower.contains("abrir") {
            if lower.contains("safari") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Safari"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Safari abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("terminal") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Terminal"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Terminal abierta."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("mail") || lower.contains("correo") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Mail"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Mail abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("music") || lower.contains("musica") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Music"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Music abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("photos") || lower.contains("fotos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Photos"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Photos abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("notes") || lower.contains("notas") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Notes"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Notes abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("calendar") || lower.contains("calendario") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Calendar"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Calendar abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("calculadora") || lower.contains("calculator") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Calculator"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Calculadora abierta."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("chrome") || lower.contains("google chrome") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Google Chrome"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Chrome abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
        }
        
        // Hora actual
        if lower.contains("hora") || lower.contains("que hora") || lower.contains("horas") {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_ES")
            let msg = "Son las " + formatter.string(from: Date()) + "."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Fecha actual
        if lower.contains("fecha") || lower.contains("que dia") || lower.contains("que fecha") || lower.contains("dia es hoy") {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "es_ES")
            let msg = "Hoy es " + formatter.string(from: Date()) + "."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Crear nota
        if lower.contains("nota") || lower.contains("apunta") || lower.contains("anota") || lower.contains("crea una nota") {
            let _ = orchestrator.execute(toolName: "write_note", arguments: ["title": "Nota rapida", "content": "Nota creada desde MACRON el " + DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)])
            let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Notes"])
            if res.contains("❌") || res.contains("no encontrada") {
                onAIResponse?(res); speak(res); return res
            }
            let msg = "Nota creada y Notes abierto."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Organizar escritorio
        if lower.contains("organiza") && lower.contains("escritorio") {
            let result = SmartFileOrganizer.shared.organizeDesktop()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }

        // Screen OCR
        if lower.contains("lee esta pantalla") || lower.contains("lea esta pantalla") || lower.contains("leer esta pantalla") || lower.contains("ocr") || lower.contains("reconoce texto") || lower.contains("extrae texto") || lower.contains("que dice aqui") || lower.contains("que dice ahi") {
            let result = await ScreenOCRService.shared.captureAndRecognize()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("guarda captura") || lower.contains("screenshot ocr") || lower.contains("captura pantalla ocr") {
            let result = await ScreenOCRService.shared.captureToFile()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }

        
        // Limpiar downloads
        if lower.contains("limpia") && lower.contains("downloads") || lower.contains("descargas") {
            let result = SmartFileOrganizer.shared.cleanOldFiles(days: 30)
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Buscar archivo
        if lower.contains("busca") || lower.contains("encuentra") || lower.contains("buscar") || lower.contains("donde esta") {
            let searchTerm = text.replacingOccurrences(of: "busca", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "encuentra", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "buscar", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "donde esta", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !searchTerm.isEmpty {
                let _ = orchestrator.execute(toolName: "search_spotlight", arguments: ["query": searchTerm])
                let msg = "Buscando '" + searchTerm + "' en tu Mac..."
                onAIResponse?(msg); speak(msg); return msg
            }
        }
        
        // Modo focus
        if lower.contains("modo focus") || lower.contains("focus session") || lower.contains("pomodoro") || lower.contains("concentracion") || lower.contains("concentrate") {
            let msg = "Modo Focus iniciado: 25 minutos. Concentracion total. Notificaciones silenciadas."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Diagnostico del sistema
        if lower.contains("diagnostico") || lower.contains("diagnostico del sistema") || (lower.contains("cuanto") && lower.contains("cpu")) || (lower.contains("cuanta") && lower.contains("ram")) || lower.contains("estado del sistema") {
            let health = SystemDiagnostics.shared.fullDiagnostic()
            let cpuStr = String(format: "%.1f", health.cpuUsage)
            let ramStr = String(format: "%.1f", health.memoryUsage)
            let diskStr = String(format: "%.1f", health.diskUsage)
            let topProc = health.topProcesses.first?.name ?? "N/A"
            let line1 = "Diagnostico del sistema:"
            let line2 = "CPU: " + cpuStr + "%"
            let line3 = "RAM: " + ramStr + "%"
            let line4 = "Disco: " + diskStr + "%"
            let line5 = "Top proceso: " + topProc
            let msg = line1 + "\n" + line2 + "\n" + line3 + "\n" + line4 + "\n" + line5
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Traducir
        if lower.contains("traduce") || lower.contains("traducir") || lower.contains("traduccion") {
            let result = await AITranslatorPro.shared.translateSelection()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Resumen de emails
        if (lower.contains("resume") || lower.contains("resumen")) && (lower.contains("email") || lower.contains("correo") || lower.contains("mail")) {
            let result = await AIEmailSummarizer.shared.summarizeUnread()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Saludos
        if lower.contains("hola") || lower.contains("buenos dias") || lower.contains("buenas tardes") || lower.contains("buenas noches") || lower.contains("hey macron") {
            let hour = Calendar.current.component(.hour, from: Date())
            let greeting: String
            if hour < 12 { greeting = "Buenos dias" }
            else if hour < 18 { greeting = "Buenas tardes" }
            else { greeting = "Buenas noches" }
            let msg = greeting + "! Soy MACRON, tu asistente AI local. En que puedo ayudarte hoy?"
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Despedidas
        if lower.contains("adios") || lower.contains("hasta luego") || lower.contains("chao") || lower.contains("nos vemos") {
            let msg = "Hasta luego! Estare aqui cuando me necesites."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Más apps populares
        if lower.contains("abre") || lower.contains("abrir") {
            if lower.contains("spotify") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Spotify"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Spotify abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("vscode") || lower.contains("visual studio code") || lower.contains("code") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Visual Studio Code"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "VS Code abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("zoom") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "zoom.us"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Zoom abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("finder") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Finder"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Finder abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("whatsapp") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "WhatsApp"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "WhatsApp abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("telegram") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Telegram"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Telegram abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("discord") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Discord"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Discord abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("slack") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Slack"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Slack abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("obs") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "OBS Studio"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "OBS abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("photoshop") || lower.contains("adobe photoshop") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Adobe Photoshop 2026"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Photoshop abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("premiere") || lower.contains("adobe premiere") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Adobe Premiere Pro 2026"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Premiere abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("after effects") || lower.contains("aftereffects") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Adobe After Effects 2026"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "After Effects abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("illustrator") || lower.contains("adobe illustrator") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Adobe Illustrator"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Illustrator abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("figma") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Figma"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Figma abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("blender") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Blender"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Blender abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("chatgpt") || lower.contains("chat gpt") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "ChatGPT"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "ChatGPT abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("claude") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Claude"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Claude abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("perplexity") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Perplexity"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Perplexity abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("notion") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Notion"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Notion abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("arc") || lower.contains("arc browser") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Arc"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Arc abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("brave") || lower.contains("brave browser") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Brave Browser"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Brave abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("firefox") || lower.contains("mozilla firefox") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Firefox"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Firefox abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("edge") || lower.contains("microsoft edge") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft Edge"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Edge abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("word") || lower.contains("microsoft word") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft Word"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Word abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("excel") || lower.contains("microsoft excel") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft Excel"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Excel abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("powerpoint") || lower.contains("microsoft powerpoint") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft PowerPoint"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "PowerPoint abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("teams") || lower.contains("microsoft teams") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft Teams"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Teams abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("outlook") || lower.contains("microsoft outlook") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft Outlook"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Outlook abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("onenote") || lower.contains("microsoft onenote") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Microsoft OneNote"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "OneNote abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("todoist") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Todoist"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Todoist abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("things") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Things"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Things abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("omnifocus") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "OmniFocus"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "OmniFocus abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("bear") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Bear"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Bear abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("craft") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Craft"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Craft abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("obsidian") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Obsidian"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Obsidian abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("logseq") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Logseq"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Logseq abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("reminders") || lower.contains("recordatorios") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Reminders"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Recordatorios abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("contacts") || lower.contains("contactos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Contacts"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Contactos abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("messages") || lower.contains("mensajes") || lower.contains("imessage") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Messages"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Mensajes abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("facetime") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "FaceTime"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "FaceTime abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("maps") || lower.contains("mapas") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Maps"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Mapas abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("weather") || lower.contains("clima") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Weather"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Clima abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("stocks") || lower.contains("bolsa") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Stocks"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Bolsa abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("home") || lower.contains("casa") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Home"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Home abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("shortcuts") || lower.contains("atajos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Shortcuts"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Atajos abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("automator") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Automator"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Automator abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("script editor") || lower.contains("editor de scripts") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Script Editor"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Editor de Scripts abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("console") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Console"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Console abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("activity monitor") || lower.contains("monitor de actividad") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Activity Monitor"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Monitor de Actividad abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("disk utility") || lower.contains("utilidad de discos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Disk Utility"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Utilidad de Discos abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("system settings") || lower.contains("system preferences") || lower.contains("ajustes del sistema") || lower.contains("preferencias del sistema") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "System Settings"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Ajustes del Sistema abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("app store") || lower.contains("tienda de apps") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "App Store"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "App Store abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("preview") || lower.contains("vista previa") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Preview"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Vista Previa abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("quicktime") || lower.contains("quicktime player") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "QuickTime Player"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "QuickTime Player abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("garageband") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "GarageBand"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "GarageBand abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("logic pro") || lower.contains("logic pro x") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Logic Pro"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Logic Pro abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("final cut") || lower.contains("final cut pro") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Final Cut Pro"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Final Cut Pro abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("motion") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Motion"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Motion abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("compressor") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Compressor"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Compressor abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("mainstage") || lower.contains("mainstage 3") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "MainStage 3"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "MainStage abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("pages") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Pages"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Pages abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("numbers") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Numbers"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Numbers abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("keynote") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Keynote"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Keynote abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("ibooks") || lower.contains("books") || lower.contains("libros") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Books"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Libros abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("podcasts") || lower.contains("podcast") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Podcasts"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Podcasts abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("news") || lower.contains("noticias") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "News"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Noticias abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("tv") || lower.contains("apple tv") || lower.contains("television") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "TV"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Apple TV abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("app store") || lower.contains("appstore") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "App Store"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "App Store abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("textedit") || lower.contains("text edit") || lower.contains("editor de texto") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "TextEdit"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "TextEdit abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("time machine") || lower.contains("maquina del tiempo") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Time Machine"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Time Machine abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("migration assistant") || lower.contains("asistente de migracion") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Migration Assistant"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Asistente de Migracion abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("boot camp") || lower.contains("bootcamp") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Boot Camp Assistant"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Boot Camp abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("colorSync") || lower.contains("colorsync utility") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "ColorSync Utility"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "ColorSync Utility abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("grab") || lower.contains("captura") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Grab"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Captura abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("stickies") || lower.contains("notas adhesivas") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Stickies"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Notas Adhesivas abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("chess") || lower.contains("ajedrez") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Chess"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Ajedrez abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("game center") || lower.contains("centro de juegos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Game Center"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Game Center abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("dvd player") || lower.contains("reproductor dvd") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "DVD Player"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Reproductor DVD abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("voice memos") || lower.contains("notas de voz") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Voice Memos"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Notas de Voz abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("find my") || lower.contains("buscar") || lower.contains("encontrar") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Find My"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Buscar abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("freeform") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Freeform"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Freeform abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("passkeys") || lower.contains("contrasenas") || lower.contains("passwords") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Passwords"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Contrasenas abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("image playground") || lower.contains("playground de imagen") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Image Playground"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Image Playground abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("genmoji") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Genmoji"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Genmoji abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("siri") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Siri"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Siri abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("wallet") || lower.contains("cartera") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Wallet"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Cartera abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("health") || lower.contains("salud") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Health"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Salud abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("fitness") || lower.contains("ejercicio") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Fitness"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Ejercicio abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("translate") || lower.contains("traductor") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Translate"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Traductor abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("measure") || lower.contains("medir") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Measure"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Medir abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("magnifier") || lower.contains("lupa") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Magnifier"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Lupa abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("shortcuts") || lower.contains("atajos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Shortcuts"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Atajos abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("tips") || lower.contains("consejos") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Tips"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Consejos abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("feedback") || lower.contains("retroalimentacion") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Feedback Assistant"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Feedback Assistant abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("terminal") || lower.contains("terminal") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Terminal"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Terminal abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("console") || lower.contains("consola") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Console"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Consola abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("instruments") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Instruments"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Instruments abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("simulator") || lower.contains("simulador") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Simulator"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Simulador abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("reality composer") || lower.contains("realitycomposer") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Reality Composer"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Reality Composer abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("reality converter") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Reality Converter"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Reality Converter abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("create ml") || lower.contains("createml") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Create ML"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "Create ML abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("sf symbols") || lower.contains("sf symbols 6") {
                let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "SF Symbols 6"])
                if res.contains("❌") || res.contains("no encontrada") {
                    onAIResponse?(res); speak(res); return res
                }
                let msg = "SF Symbols 6 abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
        }
        
        // Comandos de sistema
        if lower.contains("sube") && (lower.contains("volumen") || lower.contains("sonido")) {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "set volume output volume (output volume of (get volume settings) + 10)"]
            try? task.run()
            let msg = "Volumen subido."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("baja") && (lower.contains("volumen") || lower.contains("sonido")) {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "set volume output volume (output volume of (get volume settings) - 10)"]
            try? task.run()
            let msg = "Volumen bajado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("mute") || lower.contains("silencio") || lower.contains("silencia") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "set volume with output muted"]
            try? task.run()
            let msg = "Sonido silenciado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("sube") && lower.contains("brillo") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to key code 144"]
            try? task.run()
            let msg = "Brillo subido."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("baja") && lower.contains("brillo") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to key code 145"]
            try? task.run()
            let msg = "Brillo bajado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("bloquea") || lower.contains("lock") || lower.contains("bloquear pantalla") {
            let task = Process()
            task.launchPath = "/usr/bin/pmset"
            task.arguments = ["displaysleepnow"]
            try? task.run()
            let msg = "Pantalla bloqueada."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("apaga") && (lower.contains("pantalla") || lower.contains("monitor")) {
            let task = Process()
            task.launchPath = "/usr/bin/pmset"
            task.arguments = ["displaysleepnow"]
            try? task.run()
            let msg = "Pantalla apagada."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("duerme") || lower.contains("sleep") || lower.contains("suspender") {
            let task = Process()
            task.launchPath = "/usr/bin/pmset"
            task.arguments = ["sleepnow"]
            try? task.run()
            let msg = "Mac suspendido."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("reinicia") || lower.contains("restart") {
            let msg = "Reiniciando el Mac en 10 segundos. Guarda tu trabajo."
            onAIResponse?(msg); speak(msg)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                let task = Process()
                task.launchPath = "/sbin/shutdown"
                task.arguments = ["-r", "now"]
                try? task.run()
            }
            return msg
        }
        if lower.contains("apaga") && (lower.contains("mac") || lower.contains("computador") || lower.contains("ordenador") || lower.contains("pc")) {
            let msg = "Apagando el Mac en 10 segundos. Guarda tu trabajo."
            onAIResponse?(msg); speak(msg)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                let task = Process()
                task.launchPath = "/sbin/shutdown"
                task.arguments = ["-h", "now"]
                try? task.run()
            }
            return msg
        }
        if lower.contains("vaciar") && lower.contains("papelera") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"Finder\" to empty trash"]
            try? task.run()
            let msg = "Papelera vaciada."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("captura") && lower.contains("pantalla") || lower.contains("screenshot") || lower.contains("captura de pantalla") {
            let task = Process()
            task.launchPath = "/usr/sbin/screencapture"
            let path = NSHomeDirectory() + "/Desktop/Screenshot_" + String(Int(Date().timeIntervalSince1970)) + ".png"
            task.arguments = ["-x", path]
            try? task.run()
            let msg = "Captura de pantalla guardada en el escritorio."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("esconde") && lower.contains("apps") || lower.contains("oculta") && lower.contains("apps") || lower.contains("hide") && lower.contains("apps") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to set visible of every application process to false"]
            try? task.run()
            let msg = "Todas las apps ocultas."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("muestra") && lower.contains("escritorio") || lower.contains("show desktop") || lower.contains("mostrar escritorio") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"Finder\" to activate"]
            try? task.run()
            let msg = "Escritorio mostrado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("wifi") && (lower.contains("apaga") || lower.contains("desactiva") || lower.contains("off")) {
            let task = Process()
            task.launchPath = "/usr/sbin/networksetup"
            task.arguments = ["-setairportpower", "en0", "off"]
            try? task.run()
            let msg = "WiFi apagado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("wifi") && (lower.contains("enciende") || lower.contains("activa") || lower.contains("on")) {
            let task = Process()
            task.launchPath = "/usr/sbin/networksetup"
            task.arguments = ["-setairportpower", "en0", "on"]
            try? task.run()
            let msg = "WiFi encendido."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("bluetooth") && (lower.contains("apaga") || lower.contains("desactiva") || lower.contains("off")) {
            let task = Process()
            task.launchPath = "/usr/sbin/blueutil"
            task.arguments = ["-p", "0"]
            try? task.run()
            let msg = "Bluetooth apagado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("bluetooth") && (lower.contains("enciende") || lower.contains("activa") || lower.contains("on")) {
            let task = Process()
            task.launchPath = "/usr/sbin/blueutil"
            task.arguments = ["-p", "1"]
            try? task.run()
            let msg = "Bluetooth encendido."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("no molestar") || lower.contains("do not disturb") || lower.contains("dnd") || lower.contains("focus mode") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to tell appearance preferences to set do not disturb to true"]
            try? task.run()
            let msg = "Modo No Molestar activado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("desactiva") && lower.contains("no molestar") || lower.contains("apaga") && lower.contains("no molestar") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to tell appearance preferences to set do not disturb to false"]
            try? task.run()
            let msg = "Modo No Molestar desactivado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("modo oscuro") || lower.contains("dark mode") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to tell appearance preferences to set dark mode to true"]
            try? task.run()
            let msg = "Modo oscuro activado."
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("modo claro") || lower.contains("light mode") {
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", "tell application \"System Events\" to tell appearance preferences to set dark mode to false"]
            try? task.run()
            let msg = "Modo claro activado."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Calculadora
        if lower.contains("cuanto es") || lower.contains("calcula") || lower.contains("cuanto da") {
            let expression = text
                .replacingOccurrences(of: "cuanto es", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "calcula", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "cuanto da", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "x", with: "*")
                .replacingOccurrences(of: "por", with: "*")
                .replacingOccurrences(of: "entre", with: "/")
                .replacingOccurrences(of: "dividido", with: "/")
                .replacingOccurrences(of: "mas", with: "+")
                .replacingOccurrences(of: "menos", with: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let inputPipe = Pipe()
            let outputPipe = Pipe()
            let task = Process()
            task.launchPath = "/usr/bin/bc"
            task.standardInput = inputPipe
            task.standardOutput = outputPipe
            try? task.run()
            if let inputData = (expression + "\n").data(using: .utf8) {
                inputPipe.fileHandleForWriting.write(inputData)
                inputPipe.fileHandleForWriting.closeFile()
            }
            task.waitUntilExit()
            if let result = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !result.isEmpty {
                let msg = "El resultado es " + result + "."
                onAIResponse?(msg); speak(msg); return msg
            }
        }
        
        // Fase 10: Plugin Marketplace
        if lower.contains("plugins") || lower.contains("marketplace") || lower.contains("instalar plugin") {
            let result = await PluginService.shared.listPlugins()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("instalar plugin") {
            let name = text.replacingOccurrences(of: "instalar plugin", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            let msg = await PluginService.shared.installPlugin(name: name.isEmpty ? "default" : name)
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 11: HomeKit Hub
        if lower.contains("apaga las luces") || lower.contains("enciende las luces") || lower.contains("luces") {
            let state = lower.contains("apaga") ? "apagadas" : "encendidas"
            let msg = await HomeKitService.shared.toggleLights(state: state)
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("escena") || lower.contains("modo cine") || lower.contains("modo trabajo") {
            let scene = lower.contains("cine") ? "Cine" : (lower.contains("trabajo") ? "Trabajo" : "Personalizada")
            let msg = await HomeKitService.shared.setScene(name: scene)
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("dispositivos homekit") || lower.contains("casa inteligente") {
            let msg = await HomeKitService.shared.listDevices()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 12: Smart File Organizer
        if lower.contains("organiza mi escritorio") || lower.contains("organizar escritorio") || lower.contains("limpiar escritorio") {
            let msg = await FileOrganizerService.shared.organizeDesktop()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 13: Face ID / Biometricos
        if lower.contains("desbloquear macron") || lower.contains("face id") || lower.contains("biometricos") {
            let msg = await BiometricService.shared.unlock()
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("verificar biometricos") {
            let msg = await BiometricService.shared.authenticate()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 14: Multi-idioma
        if lower.contains("traduce") || lower.contains("traducir") {
            let text = text.replacingOccurrences(of: "traduce", with: "", options: .caseInsensitive).replacingOccurrences(of: "traducir", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            let msg = await TranslatorService.shared.translate(text: text.isEmpty ? "Hola mundo" : text, to: "Ingles")
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("detecta idioma") {
            let msg = await TranslatorService.shared.detectLanguage(text: text)
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 15: Backup Encriptado
        if lower.contains("crear backup") || lower.contains("respaldar macron") || lower.contains("backup") {
            let msg = await BackupService.shared.createBackup()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 16: Modo Focus
        if lower.contains("modo focus") || lower.contains("no molestar") || lower.contains("concentracion") {
            let msg = lower.contains("desactiva") ? await FocusService.shared.disableFocus() : await FocusService.shared.enableFocus()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 17: Clipboard Manager
        if lower.contains("guardar portapapeles") || lower.contains("clipboard") || lower.contains("copiar esto") {
            let msg = await ClipboardService.shared.saveClipboard()
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("historial clipboard") || lower.contains("ver portapapeles") {
            let msg = await ClipboardService.shared.showHistory()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Fase 18: Smart Search
        if lower.contains("busca archivo") || lower.contains("buscar archivo") || lower.contains("donde esta") {
            let query = text.replacingOccurrences(of: "busca archivo", with: "", options: .caseInsensitive).replacingOccurrences(of: "buscar archivo", with: "", options: .caseInsensitive).replacingOccurrences(of: "donde esta", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            let msg = await SmartSearchService.shared.searchFiles(query: query.isEmpty ? "documento" : query)
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("busca en internet") || lower.contains("buscar web") {
            let query = text.replacingOccurrences(of: "busca en internet", with: "", options: .caseInsensitive).replacingOccurrences(of: "buscar web", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
            let msg = await SmartSearchService.shared.searchWeb(query: query.isEmpty ? "macron ai" : query)
            onAIResponse?(msg); speak(msg); return msg
        }

        // Meeting Recorder (con fuzzy matching para typos)
        if lower.contains("graba") && (lower.contains("reunion") || lower.contains("reunon") || lower.contains("reunión")) {
            let result = await MeetingRecorderService.shared.startRecording()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        if (lower.contains("detener") || lower.contains("stop") || lower.contains("parar")) && !lower.contains("muestra") && !lower.contains("voz") {
            let result = await MeetingRecorderService.shared.stopRecording()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("transcribe") || lower.contains("trascri") || lower.contains("transcripcion") || lower.contains("texto") {
            let msg = await MeetingRecorderService.shared.transcribeLastMeeting()
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("resume") || lower.contains("resumen") || lower.contains("resumir") {
            let msg = await MeetingRecorderService.shared.summarizeMeeting()
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("grabaciones") || lower.contains("recordings") || lower.contains("lista") {
            let result = await MeetingRecorderService.shared.listRecordings()
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }
        if lower.contains("reproduce") || lower.contains("escuchar") || lower.contains("play") || lower.contains("muestrame") {
            let msg = await MeetingRecorderService.shared.playLastRecording()
            onAIResponse?(msg); speak(msg); return msg
        }

        // Calendario real
        if (lower.contains("reunete") || lower.contains("reunion") || lower.contains("agenda") || lower.contains("crea evento") || lower.contains("nueva reunion") || lower.contains("programa")) && (lower.contains("manana") || lower.contains("hoy") || lower.contains("proxima") || lower.contains("semana")) {
            let script = """
            tell application "Calendar"
                set newEvent to make new event at end of events of calendar "Home" with properties {summary:"Reunion MACRON", start date:(current date), end date:(current date + 3600)}
            end tell
            """
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            try? task.run()
            let msg = "Evento creado en tu calendario."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Recordatorios
        if lower.contains("recuerdame") || lower.contains("recordatorio") || lower.contains("recuerda") {
            let reminder = text
                .replacingOccurrences(of: "recuerdame", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "recordatorio", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "recuerda", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let script = """
            tell application "Reminders"
                make new reminder with properties {name:"\(reminder)"}
            end tell
            """
            let task = Process()
            task.launchPath = "/usr/bin/osascript"
            task.arguments = ["-e", script]
            try? task.run()
            let msg = "Recordatorio creado: " + reminder
            onAIResponse?(msg); speak(msg); return msg
        }

        // Calendario real
        if lower.contains("reunete") || lower.contains("reunion") || lower.contains("agenda") || lower.contains("crea evento") || lower.contains("programa") || lower.contains("nueva reunion") {
            let title = CalendarService.shared.extractTitle(from: text)
            let dateComponents = CalendarService.shared.parseNaturalDate(text: text)
            let result = await CalendarService.shared.createEvent(title: title, dateComponents: dateComponents)
            let msg = result
            onAIResponse?(msg); speak(msg); return msg
        }

        let enriched = contextEngine.enrichPrompt(text)
        var response: String
        if useReasoning, needsReasoning(text) {
            response = await reasoning.reason(about: enriched, llmGenerate: generateLLMResponse)
        } else {
            response = await generateLLMResponse(enriched)
            if let d = orchestrator.parseLLMDecision(response) {
                let res = orchestrator.execute(toolName: d.toolName, arguments: d.args)
                let followUpSystem = "Eres MACRON. Responde SIEMPRE en espanol natural, corto y util. MAXIMO 2 frases. NO uses JSON. NO uses codigo."
                response = await LLMConnector.shared.generate(
                    prompt: "El usuario dijo: \"" + text + "\"\nEjecutaste la accion y obtuviste: " + res + "\nResponde al usuario en espanol natural.",
                    systemPrompt: followUpSystem
                )
            }
        }
        onAIResponse?(response); speak(response)
        return response
    }
    private func generateLLMResponse(_ prompt: String) async -> String {
        let tools = orchestrator.toolDescriptions()
        let systemPrompt = "Eres MACRON, un asistente AI amigable para macOS. Tienes acceso a estas herramientas:\n" + tools + "\n\nINSTRUCCIONES CRITICAS:\n1. Si necesitas usar una herramienta, responde UNICAMENTE con JSON PLANO (sin markdown, sin texto extra):\n{\"tool\": \"nombre\", \"args\": {\"param\": \"valor\"}}\n2. Si NO necesitas herramienta, responde directamente al usuario en ESPANOL NATURAL y AMIGABLE.\n3. NUNCA mezcles JSON con texto explicativo."
        let response = await LLMConnector.shared.generate(prompt: prompt, systemPrompt: systemPrompt)
        if response.hasPrefix("Error") || response.hasPrefix("URL invalida") {
            // Fallback: si Ollama no responde, usar logica local
            if prompt.lowercased().contains("abre") || prompt.lowercased().contains("abrir") {
                if prompt.lowercased().contains("safari") { return "```json\n{\"tool\": \"open_app\", \"args\": {\"app_name\": \"Safari\"}}\n```" }
            }
            if prompt.lowercased().contains("nota") || prompt.lowercased().contains("apunta") {
                return "```json\n{\"tool\": \"write_note\", \"args\": {\"title\": \"Nota rapida\", \"content\": \"Contenido\"}}\n```"
            }
            return "Entendido. Procesado con contexto de " + contextEngine.currentContext.appName + ". Ollama no disponible. ¿En que mas puedo ayudarte?"
        }
        return response
    }
    private func setupTranscriber() {
        transcriber.onTranscript = { [weak self] text, isFinal in
            guard let self = self, isFinal else { return }
            let l = text.lowercased()
            if l.contains(self.wakeWord.lowercased()) {
                let q = text.replacingOccurrences(of: self.wakeWord, with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
                Task { _ = await self.processUserMessage(q.isEmpty ? "¿Si?" : q, source: .voice) }
            }
        }
    }
    private func needsReasoning(_ text: String) -> Bool {
        let triggers = ["compara","analiza","investiga","busca","encuentra","resumen","resume","explica paso a paso","por que","como funciona","planifica","organiza","decide","calcula","multi-paso"]
        return triggers.contains { text.lowercased().contains($0) }
    }
    private func speak(_ text: String) {
        onSystemMessage?("🗣️ MACRON dice: \(text)")
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }
    private func setupNotifications() {
        let focus = UNNotificationAction(identifier: "focus_start", title: "Iniciar Focus", options: [])
        let dismiss = UNNotificationAction(identifier: "dismiss", title: "Descartar", options: [])
        UNUserNotificationCenter.current().setNotificationCategories([UNNotificationCategory(identifier: "macron_proactive", actions: [focus, dismiss], intentIdentifiers: [])])
    }
    public enum MessageSource: Sendable { case voice, text, proactive, shortcut }
}
