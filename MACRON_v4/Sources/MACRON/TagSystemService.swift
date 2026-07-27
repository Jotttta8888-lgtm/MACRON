import Foundation

class TagSystemService: ObservableObject {
    static let shared = TagSystemService()
    @Published var tags: [TagItem] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/tags.json"
    
    struct TagItem: Identifiable, Codable {
        var id = UUID()
        let name: String
        let color: String
        var items: [TaggedItem] = []
    }
    
    struct TaggedItem: Identifiable, Codable {
        var id = UUID()
        let title: String
        let type: String
        let reference: String
    }
    
    func createTag(name: String, color: String = "blue") {
        let tag = TagItem(name: name, color: color)
        tags.append(tag)
        save()
    }
    
    func addItemToTag(tagName: String, title: String, type: String, reference: String) {
        guard let idx = tags.firstIndex(where: { $0.name == tagName }) else { return }
        let item = TaggedItem(title: title, type: type, reference: reference)
        tags[idx].items.append(item)
        save()
    }
    
    func searchByTag(_ tagName: String) -> [TaggedItem] {
        return tags.first(where: { $0.name == tagName })?.items ?? []
    }
    
    func getAllTags() -> [String] {
        return tags.map { $0.name }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(tags)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([TagItem].self, from: data) else { return }
        tags = decoded
    }
}
