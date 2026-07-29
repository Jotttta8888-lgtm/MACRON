import Foundation
import AppKit

public final class ClipboardSync: @unchecked Sendable {
    public static let shared = ClipboardSync()
    
    public struct ClipboardItem: Identifiable, Codable, Sendable {
        public var id = UUID()
        public let content: String
        public let type: ItemType
        public let timestamp: Date
        public let sourceDevice: String
        
        public enum ItemType: String, Codable, Sendable {
            case text, url, email, code, color
        }
    }
    
    @Published public private(set) var history: [ClipboardItem] = []
    @Published public private(set) var isMonitoring = false
    
    private var lastContent: String = ""
    private var timer: Timer?
    private let maxHistory = 100
    private let historyKey = "macron_clipboard_history"
    
    private init() {
        loadHistory()
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    public func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    public func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
        NotificationService.shared.send(
            title: "Portapapeles",
            body: "Copiado: " + String(item.content.prefix(50))
        )
    }
    
    public func clearHistory() {
        history.removeAll()
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    public func searchHistory(query: String) -> [ClipboardItem] {
        let lower = query.lowercased()
        return history.filter { $0.content.lowercased().contains(lower) }
    }
    
    public func exportHistory() -> String {
        var lines: [String] = []
        lines.append("HISTORIAL MACRON CLIPBOARD")
        lines.append("==========================")
        for item in history {
            let date = DateFormatter.localizedString(from: item.timestamp, dateStyle: .short, timeStyle: .short)
            lines.append("[" + date + "] [" + item.type.rawValue + "] " + item.content.prefix(100))
        }
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Private
    
    private func checkClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else { return }
        guard content != lastContent else { return }
        lastContent = content
        
        let type = detectType(content)
        let item = ClipboardItem(
            content: content,
            type: type,
            timestamp: Date(),
            sourceDevice: Host.current().localizedName ?? "Mac NEO"
        )
        
        history.insert(item, at: 0)
        if history.count > maxHistory { history.removeLast() }
        saveHistory()
    }
    
    private func detectType(_ content: String) -> ClipboardItem.ItemType {
        if content.hasPrefix("http://") || content.hasPrefix("https://") { return .url }
        if content.contains("@") && content.contains(".") { return .email }
        if content.hasPrefix("#") && content.count == 7 { return .color }
        if content.contains("func ") || content.contains("class ") || content.contains("import ") { return .code }
        return .text
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        history = items
    }
}
