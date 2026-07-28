import Foundation
import AppKit

public final class SmartSearch: @unchecked Sendable {
    public static let shared = SmartSearch()
    
    public struct SearchResult: Identifiable, Sendable {
        public let id = UUID()
        public let title: String
        public let subtitle: String
        public let type: ResultType
        public let path: String?
        public let action: @Sendable () -> Void
    }
    
    public enum ResultType: String, Sendable {
        case app, file, note, web, command
    }
    
    private init() {}
    
    public func search(_ query: String) async -> [SearchResult] {
        let lower = query.lowercased()
        var results: [SearchResult] = []
        results.append(contentsOf: searchApps(query: lower))
        results.append(contentsOf: await searchFiles(query: lower))
        results.append(contentsOf: searchNotes(query: lower))
        results.append(contentsOf: searchCommands(query: lower))
        
        if lower.count > 2 {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlStr = "https://google.com/search?q=" + encoded
            results.append(SearchResult(
                title: "Buscar " + query + " en Google",
                subtitle: "Web",
                type: .web,
                path: nil,
                action: { if let url = URL(string: urlStr) { NSWorkspace.shared.open(url) } }
            ))
        }
        return Array(results.prefix(20))
    }
    
    private func searchApps(query: String) -> [SearchResult] {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        var results: [SearchResult] = []
        for app in apps {
            guard let name = app.localizedName, name.lowercased().contains(query) else { continue }
            let bundleURL = app.bundleURL
            results.append(SearchResult(
                title: name,
                subtitle: "App en ejecucion",
                type: .app,
                path: bundleURL?.path,
                action: { if let url = bundleURL { NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) } }
            ))
        }
        return results
    }
    
    private func searchFiles(query: String) async -> [SearchResult] {
        let mq = NSMetadataQuery()
        mq.predicate = NSPredicate(format: "kMDItemDisplayName CONTAINS[cd] %@", query)
        mq.searchScopes = [NSMetadataQueryLocalComputerScope]
        mq.start()
        try? await Task.sleep(nanoseconds: 500_000_000)
        var results: [SearchResult] = []
        for i in 0..<min(mq.resultCount, 10) {
            guard let item = mq.result(at: i) as? NSMetadataItem,
                  let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                  let name = item.value(forAttribute: NSMetadataItemDisplayNameKey) as? String else { continue }
            let type = path.hasSuffix(".md") || path.hasSuffix(".txt") ? ResultType.note : .file
            results.append(SearchResult(
                title: name,
                subtitle: path,
                type: type,
                path: path,
                action: { NSWorkspace.shared.open(URL(fileURLWithPath: path)) }
            ))
        }
        mq.stop()
        return results
    }
    
    private func searchNotes(query: String) -> [SearchResult] {
        let notesDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/MACRON/Notes")
        guard let files = try? FileManager.default.contentsOfDirectory(at: notesDir, includingPropertiesForKeys: nil) else { return [] }
        var results: [SearchResult] = []
        for file in files {
            guard let content = try? String(contentsOf: file, encoding: .utf8),
                  content.lowercased().contains(query) else { continue }
            let title = file.lastPathComponent.replacingOccurrences(of: ".md", with: "")
            let preview = String(content.prefix(100)).replacingOccurrences(of: "\n", with: " ")
            results.append(SearchResult(
                title: title,
                subtitle: preview,
                type: .note,
                path: file.path,
                action: { NSWorkspace.shared.open(file) }
            ))
        }
        return results
    }
    
    private func searchCommands(query: String) -> [SearchResult] {
        let commands: [(String, String, @Sendable () -> Void)] = [
            ("Modo Focus", "FocusSessionsPro", { FocusSessionsPro.shared.startSession(type: .pomodoro) }),
            ("Abrir Terminal", "System", { _ = AgentOrchestrator.shared.execute(toolName: "open_app", arguments: ["app_name": "Terminal"]) }),
            ("Diagnostico del sistema", "SystemDiagnostics", { _ = SystemDiagnostics.shared.quickReport() }),
            ("Activar Brain", "MACRON", { MACRONBrain.shared.boot() }),
        ]
        return commands.filter { $0.0.lowercased().contains(query) }.map { cmd in
            SearchResult(title: cmd.0, subtitle: cmd.1, type: .command, path: nil, action: cmd.2)
        }
    }
}
