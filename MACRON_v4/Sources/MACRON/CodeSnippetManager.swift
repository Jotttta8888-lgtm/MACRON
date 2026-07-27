import Foundation

class CodeSnippetManager: ObservableObject {
    static let shared = CodeSnippetManager()
    @Published var snippets: [CodeSnippet] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/snippets.json"
    
    struct CodeSnippet: Identifiable, Codable {
        var id = UUID()
        let title: String
        let code: String
        let language: String
        let tags: [String]
        let createdAt: Date
    }
    
    func addSnippet(title: String, code: String, language: String, tags: [String]) {
        let snippet = CodeSnippet(title: title, code: code, language: language, tags: tags, createdAt: Date())
        snippets.insert(snippet, at: 0)
        save()
        NotificationService.shared.send(title: "MACRON", body: "Snippet guardado: " + title)
    }
    
    func search(query: String) -> [CodeSnippet] {
        let lower = query.lowercased()
        return snippets.filter {
            $0.title.lowercased().contains(lower) ||
            $0.code.lowercased().contains(lower) ||
            $0.language.lowercased().contains(lower)
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(snippets)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([CodeSnippet].self, from: data) else { return }
        snippets = decoded
    }
}
