import AppKit
import Combine

class ClipboardHistoryService: ObservableObject {
    static let shared = ClipboardHistoryService()
    @Published var items: [ClipboardItem] = []
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let maxItems = 50
    
    struct ClipboardItem: Identifiable, Codable {
        let id = UUID()
        let text: String
        let timestamp: Date
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
    }
    
    private func checkClipboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        guard let text = pb.string(forType: .string), !text.isEmpty else { return }
        let item = ClipboardItem(text: text, timestamp: Date())
        DispatchQueue.main.async {
            self.items.insert(item, at: 0)
            if self.items.count > self.maxItems {
                self.items.removeLast()
            }
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func clear() {
        items.removeAll()
    }
}
