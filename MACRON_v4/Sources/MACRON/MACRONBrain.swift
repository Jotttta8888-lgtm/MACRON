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
        let enriched = contextEngine.enrichPrompt(text)
        var response: String
        if useReasoning, needsReasoning(text) {
            response = await reasoning.reason(about: enriched, llmGenerate: generateLLMResponse)
        } else {
            response = await generateLLMResponse(enriched)
            if let d = orchestrator.parseLLMDecision(response) {
                let res = orchestrator.execute(toolName: d.toolName, arguments: d.args)
                response = await generateLLMResponse("El usuario pregunto: \(text)\nEjecutaste '\(d.toolName)' y obtuviste: \(res)\nResponde al usuario.")
            }
        }
        onAIResponse?(response); speak(response)
        return response
    }
    private func generateLLMResponse(_ prompt: String) async -> String {
        let tools = orchestrator.toolDescriptions()
        _ = "\(tools)\n\nSi necesitas herramienta, responde UNICAMENTE con JSON:\n```json\n{\"tool\": \"nombre\", \"args\": {\"param\": \"valor\"}}\n```\n\n\(prompt)"
        // Reemplazar por: return await LLMService.shared.generate(prompt: full)
        if prompt.lowercased().contains("abre") || prompt.lowercased().contains("abrir") {
            if prompt.lowercased().contains("safari") { return "```json\n{\"tool\": \"open_app\", \"args\": {\"app_name\": \"Safari\"}}\n```" }
        }
        if prompt.lowercased().contains("nota") || prompt.lowercased().contains("apunta") {
            return "```json\n{\"tool\": \"write_note\", \"args\": {\"title\": \"Nota rapida\", \"content\": \"Contenido\"}}\n```"
        }
        return "Entendido. Procesado con contexto de \(contextEngine.currentContext.appName). ¿En que mas puedo ayudarte?"
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
