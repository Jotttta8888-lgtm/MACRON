import Foundation
import AppKit

class SmartHomeScenesService: ObservableObject {
    static let shared = SmartHomeScenesService()
    @Published var scenes: [SmartScene] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/scenes.json"
    
    struct SmartScene: Identifiable, Codable {
        var id = UUID()
        let name: String
        let actions: [String]
        let icon: String
    }
    
    func addScene(name: String, actions: [String], icon: String = "house") {
        let scene = SmartScene(name: name, actions: actions, icon: icon)
        scenes.append(scene)
        save()
    }
    
    func activateScene(_ sceneName: String) {
        guard let scene = scenes.first(where: { $0.name == sceneName }) else { return }
        for action in scene.actions {
            executeAction(action)
        }
        NotificationService.shared.send(title: "MACRON Home", body: "Escena activada: " + sceneName)
    }
    
    private func executeAction(_ action: String) {
        if action.hasPrefix("osascript:") {
            let script = action.replacingOccurrences(of: "osascript:", with: "")
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            try? task.run()
        } else if action.hasPrefix("open:") {
            let url = action.replacingOccurrences(of: "open:", with: "")
            if let u = URL(string: url) {
                NSWorkspace.shared.open(u)
            }
        } else if action.hasPrefix("shell:") {
            let cmd = action.replacingOccurrences(of: "shell:", with: "")
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-c", cmd]
            try? task.run()
        }
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(scenes)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([SmartScene].self, from: data) else { return }
        scenes = decoded
    }
}
