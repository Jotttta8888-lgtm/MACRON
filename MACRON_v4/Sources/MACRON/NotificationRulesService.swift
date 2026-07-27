import Foundation
import AppKit

class NotificationRulesService: ObservableObject {
    static let shared = NotificationRulesService()
    @Published var rules: [NotificationRule] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/notif_rules.json"
    
    struct NotificationRule: Identifiable, Codable {
        var id = UUID()
        let name: String
        let condition: String
        let action: String
        let isActive: Bool
    }
    
    func addRule(name: String, condition: String, action: String) {
        let rule = NotificationRule(name: name, condition: condition, action: action, isActive: true)
        rules.append(rule)
        save()
        NotificationService.shared.send(title: "MACRON Rules", body: "Regla creada: " + name)
    }
    
    func evaluate(appName: String, title: String, body: String) {
        for rule in rules where rule.isActive {
            let text = (appName + " " + title + " " + body).lowercased()
            if text.contains(rule.condition.lowercased()) {
                executeAction(rule.action)
            }
        }
    }
    
    private func executeAction(_ action: String) {
        if action.hasPrefix("notify:") {
            let msg = action.replacingOccurrences(of: "notify:", with: "")
            NotificationService.shared.send(title: "MACRON Rule", body: msg)
        } else if action.hasPrefix("shell:") {
            let cmd = action.replacingOccurrences(of: "shell:", with: "")
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-c", cmd]
            try? task.run()
        } else if action.hasPrefix("open:") {
            let url = action.replacingOccurrences(of: "open:", with: "")
            if let u = URL(string: url) {
                NSWorkspace.shared.open(u)
            }
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(rules)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([NotificationRule].self, from: data) else { return }
        rules = decoded
    }
}
