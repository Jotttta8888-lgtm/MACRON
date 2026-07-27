import Foundation

class JournalService: ObservableObject {
    static let shared = JournalService()
    @Published var entries: [JournalEntry] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/journal.json"
    
    struct JournalEntry: Identifiable, Codable {
        var id = UUID()
        let date: Date
        let content: String
        let mood: String
        let tags: [String]
    }
    
    func addEntry(content: String, mood: String) {
        let entry = JournalEntry(date: Date(), content: content, mood: mood, tags: extractTags(content))
        entries.insert(entry, at: 0)
        save()
        NotificationService.shared.send(title: "MACRON Journal", body: "Entrada guardada")
    }
    
    func getEntriesForDate(_ date: Date) -> [JournalEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: date) }
    }
    
    func search(query: String) -> [JournalEntry] {
        let lower = query.lowercased()
        return entries.filter { $0.content.lowercased().contains(lower) || $0.mood.lowercased().contains(lower) }
    }
    
    private func extractTags(_ text: String) -> [String] {
        let pattern = "#\\w+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        return matches.compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(entries)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else { return }
        entries = decoded
    }
}
