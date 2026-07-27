import Foundation

struct Plugin: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let type: PluginType
    let path: String
    let command: String
    
    enum PluginType: String, Codable {
        case python, swift, applescript, shell
    }
}

class PluginSystem: ObservableObject {
    static let shared = PluginSystem()
    @Published var plugins: [Plugin] = []
    private let pluginsDir = NSHomeDirectory() + "/Documents/MACRON/plugins"
    
    func scanPlugins() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: pluginsDir) else { plugins = []; return }
        var scanned: [Plugin] = []
        for file in files {
            let path = pluginsDir + "/\(file)"
            let ext = (file as NSString).pathExtension.lowercased()
            let type: Plugin.PluginType
            switch ext {
            case "py": type = .python
            case "swift": type = .swift
            case "scpt", "applescript": type = .applescript
            case "sh": type = .shell
            default: continue
            }
            let content = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
            let lines = content.components(separatedBy: .newlines)
            let name = lines.first { $0.contains("# NAME:") }?.replacingOccurrences(of: "# NAME:", with: "").trimmingCharacters(in: .whitespaces) ?? file
            let desc = lines.first { $0.contains("# DESC:") }?.replacingOccurrences(of: "# DESC:", with: "").trimmingCharacters(in: .whitespaces) ?? "Sin descripcion"
            scanned.append(Plugin(name: name, description: desc, type: type, path: path, command: file))
        }
        plugins = scanned
    }
    
    func executePlugin(_ plugin: Plugin, input: String = "", completion: @escaping (String) -> Void) {
        let task = Process()
        let pipe = Pipe()
        let errorPipe = Pipe()
        switch plugin.type {
        case .python:
            task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            task.arguments = [plugin.path, input]
        case .swift:
            task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
            task.arguments = [plugin.path, input]
        case .applescript:
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = [plugin.path, input]
        case .shell:
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [plugin.path, input]
        }
        task.standardOutput = pipe
        task.standardError = errorPipe
        task.terminationHandler = { _ in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            completion(output.isEmpty ? error : output)
        }
        try? task.run()
    }
    
    func createExamplePlugin() {
        let example = pluginsDir + "/hola_mundo.py"
        let content = "# NAME: Hola Mundo\n# DESC: Plugin de ejemplo que saluda\nimport sys\nnombre = sys.argv[1] if len(sys.argv) > 1 else 'Mundo'\nprint(f'Hola, {nombre}! Desde el plugin de MACRON.')\n"
        if !FileManager.default.fileExists(atPath: example) {
            try? content.write(toFile: example, atomically: true, encoding: .utf8)
        }
    }
}
