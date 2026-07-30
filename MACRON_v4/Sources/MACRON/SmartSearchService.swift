import Foundation
public actor SmartSearchService {
    public static let shared = SmartSearchService()
    private init() {}
    public func searchFiles(query: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let files = (try? FileManager.default.contentsOfDirectory(at: home, includingPropertiesForKeys: nil)) ?? []
        let matches = files.filter { $0.lastPathComponent.lowercased().contains(query.lowercased()) }.prefix(5)
        if matches.isEmpty { return "🔍 No se encontraron archivos para '\(query)'." }
        return "🔍 Resultados para '\(query)':\n" + matches.map { "  • \($0.lastPathComponent)" }.joined(separator: "\n")
    }
    public func searchWeb(query: String) -> String { "🔍 Busqueda web: https://duckduckgo.com/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
}
