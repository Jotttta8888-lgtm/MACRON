import Foundation
public actor ClipboardService {
    public static let shared = ClipboardService()
    private var history: [String] = []
    private init() {}
    
    public func saveClipboard() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/pbpaste"
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            return "📋 Portapapeles vacio."
        }
        history.append(text)
        return "📋 Guardado en historial: '\(text.prefix(50))...'"
    }
    
    public func showHistory() -> String {
        if history.isEmpty { return "📋 Historial vacio." }
        return "📋 Historial (\(history.count)):\n" + history.enumerated().map { "\($0+1). \($1.prefix(40))" }.joined(separator: "\n")
    }
}
