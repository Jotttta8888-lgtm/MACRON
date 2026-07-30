import Foundation
import AppKit
import Speech
import UserNotifications

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
                let _ = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Safari"])
                let msg = "Safari abierto."
                onAIResponse?(msg); speak(msg); return msg
            }
            if lower.contains("terminal") {
                let _ = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Terminal"])
                let msg = "Terminal abierta."
                onAIResponse?(msg); speak(msg); return msg
            }
        }
        
        // Hora actual
        if lower.contains("hora") || lower.contains("que hora") {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_ES")
            let msg = "Son las " + formatter.string(from: Date()) + "."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Crear nota
        if lower.contains("nota") || lower.contains("apunta") {
            let _ = orchestrator.execute(toolName: "write_note", arguments: ["title": "Nota rapida", "content": "Nota creada desde MACRON"])
            let _ = orchestrator.execute(toolName: "open_app", arguments: ["app_name": "Notes"])
            let msg = "Nota creada y Notes abierto."
            onAIResponse?(msg); speak(msg); return msg
        }
        
        // Organizar escritorio
        if lower.contains("organiza") && lower.contains("escritorio") {
            let result = SmartFileOrganizer.shared.organizeDesktop()
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
    private func speak(_ text: String) { onSystemMessage?("🗣️ MACRON dice: \(text)") }
    private func setupNotifications() {
        let focus = UNNotificationAction(identifier: "focus_start", title: "Iniciar Focus", options: [])
        let dismiss = UNNotificationAction(identifier: "dismiss", title: "Descartar", options: [])
        UNUserNotificationCenter.current().setNotificationCategories([UNNotificationCategory(identifier: "macron_proactive", actions: [focus, dismiss], intentIdentifiers: [])])
    }
    public enum MessageSource: Sendable { case voice, text, proactive, shortcut }
}
