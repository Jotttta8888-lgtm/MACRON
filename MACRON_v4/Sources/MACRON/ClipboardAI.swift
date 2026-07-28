import Foundation
import AppKit

public final class ClipboardAI: @unchecked Sendable {
    public static let shared = ClipboardAI()
    private var lastContent: String = ""
    private var history: [ClipboardItem] = []
    private let maxHistory = 20
    private var timer: Timer?
    
    public struct ClipboardItem: Identifiable {
        public let id = UUID()
        public let content: String
        public let type: ClipboardType
        public let timestamp: Date
    }
    public enum ClipboardType: String { case url, email, phone, code, text, unknown }
    private init() {}
    
    public func startMonitoring(interval: TimeInterval = 1.0) {
        stopMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in self?.checkClipboard() }
    }
    public func stopMonitoring() { timer?.invalidate(); timer = nil }
    
    private func checkClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string), content != lastContent else { return }
        lastContent = content
        let type = classify(content)
        let item = ClipboardItem(content: content, type: type, timestamp: Date())
        history.append(item)
        if history.count > maxHistory { history.removeFirst() }
        let suggestion = suggestAction(for: item)
        if !suggestion.isEmpty { NotificationCenter.default.post(name: .init("macron_clipboard_suggestion"), object: suggestion) }
    }
    
    private func classify(_ text: String) -> ClipboardType {
        if text.hasPrefix("http") || text.hasPrefix("www.") { return .url }
        if text.contains("@") && text.contains(".") { return .email }
        if text.range(of: #"^\\+?\\d[\\d\\s\\-\\(\\)]{7,}$"#, options: .regularExpression) != nil { return .phone }
        if text.contains("func ") || text.contains("class ") || text.contains("import ") || text.contains("{") { return .code }
        return .text
    }
    
    private func suggestAction(for item: ClipboardItem) -> String {
        switch item.type {
        case .url: return "🌐 Copiaste una URL. ¿Quieres abrirla en Safari?"
        case .email: return "📧 Copiaste un email. ¿Quieres redactar un mensaje?"
        case .phone: return "📞 Copiaste un telefono. ¿Quieres guardarlo como contacto?"
        case .code: return "👨‍💻 Copiaste codigo. ¿Quieres que lo formatee o explique?"
        case .text where item.content.count > 100: return "📝 Copiaste un texto largo. ¿Quieres que lo resuma?"
        default: return ""
        }
    }
    
    public func executeSuggestion(_ item: ClipboardItem) -> String {
        switch item.type {
        case .url: if let url = URL(string: item.content) { NSWorkspace.shared.open(url); return "✅ URL abierta." }; return "❌ URL invalida."
        case .email: return EmailDraftAI.shared.draftEmail(to: item.content, about: "Hola, te escribo para...")
        case .phone: let vcard = "BEGIN:VCARD\\nVERSION:3.0\\nFN:Contacto MACRON\\nTEL:\(item.content)\\nEND:VCARD"; NSPasteboard.general.clearContents(); NSPasteboard.general.setString(vcard, forType: .string); return "✅ vCard copiado. Pega en Contactos para guardar."
        case .code: return CodeAssistant.shared.explainError(item.content)
        default: return DocumentAI.shared.answerQuestion(item.content)
        }
    }
    public func getHistory() -> [ClipboardItem] { history }
    public func clearHistory() { history.removeAll(); lastContent = "" }
}
