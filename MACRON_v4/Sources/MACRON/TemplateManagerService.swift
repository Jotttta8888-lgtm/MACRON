import Foundation
import AppKit

class TemplateManagerService: ObservableObject {
    static let shared = TemplateManagerService()
    @Published var templates: [TextTemplate] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/templates.json"
    
    struct TextTemplate: Identifiable, Codable {
        var id = UUID()
        let shortcut: String
        let expansion: String
        let category: String
    }
    
    func addTemplate(shortcut: String, expansion: String, category: String = "General") {
        let tmpl = TextTemplate(shortcut: shortcut, expansion: expansion, category: category)
        templates.append(tmpl)
        save()
        NotificationService.shared.send(title: "MACRON Templates", body: "Plantilla añadida: " + shortcut)
    }
    
    func expand(_ shortcut: String) -> String? {
        return templates.first(where: { $0.shortcut == shortcut })?.expansion
    }
    
    func expandAndCopy(_ shortcut: String) {
        guard let text = expand(shortcut) else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        NotificationService.shared.send(title: "MACRON Templates", body: "Expandido y copiado: " + shortcut)
    }
    
    func getByCategory(_ category: String) -> [TextTemplate] {
        return templates.filter { $0.category == category }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(templates)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([TextTemplate].self, from: data) else { return }
        templates = decoded
    }
}
