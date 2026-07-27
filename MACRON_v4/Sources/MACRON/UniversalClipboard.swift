import Foundation
import AppKit

class UniversalClipboard: ObservableObject {
    static let shared = UniversalClipboard()
    @Published var lastSyncedItem = ""
    
    func syncToCloud(_ text: String) {
        let path = NSHomeDirectory() + "/Library/Mobile Documents/com~apple~CloudDocs/MACRON_clipboard.txt"
        try? text.write(toFile: path, atomically: true, encoding: .utf8)
        lastSyncedItem = text
        NotificationService.shared.send(title: "MACRON", body: "Portapapeles sincronizado con iCloud")
    }
    
    func syncFromCloud() -> String? {
        let path = NSHomeDirectory() + "/Library/Mobile Documents/com~apple~CloudDocs/MACRON_clipboard.txt"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        lastSyncedItem = text
        NotificationService.shared.send(title: "MACRON", body: "Portapapeles recuperado de iCloud")
        return text
    }
}
