import Foundation
import AppKit
import UserNotifications

public final class AgentOrchestrator: @unchecked Sendable {
    public static let shared = AgentOrchestrator()
    
    public struct Tool {
        public let name: String
        public let description: String
        public let parameters: [String: String]
        public let execute: ([String: String]) throws -> String
        
        public init(name: String, description: String, parameters: [String: String], execute: @escaping ([String: String]) throws -> String) {
            self.name = name
            self.description = description
            self.parameters = parameters
            self.execute = execute
        }
    }
    
    private var tools: [String: Tool] = [:]
    private let syncQueue = DispatchQueue(label: "macron.orchestrator")
    
    private init() {
        registerDefaultTools()
    }
    
    public func register(tool: Tool) {
        syncQueue.sync { tools[tool.name] = tool }
    }
    
    public func toolDescriptions() -> String {
        return syncQueue.sync {
            var lines: [String] = []
            lines.append("=== HERRAMIENTAS DISPONIBLES ===")
            for (_, tool) in tools {
                lines.append("\n🔧 \(tool.name): \(tool.description)")
                if !tool.parameters.isEmpty {
                    lines.append("   Parametros:")
                    for (param, type) in tool.parameters {
                        lines.append("     - \(param): \(type)")
                    }
                }
            }
            lines.append("\n================================")
            return lines.joined(separator: "\n")
        }
    }
    
    public func execute(toolName: String, arguments: [String: String]) -> String {
        let tool = syncQueue.sync { tools[toolName] }
        guard let tool = tool else { return "❌ Tool '\(toolName)' no encontrada." }
        do { return try tool.execute(arguments) } catch { return "❌ Error: \(error.localizedDescription)" }
    }
    
    public func parseLLMDecision(_ raw: String) -> (toolName: String, args: [String: String])? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var jsonStr = trimmed
        
        // Quitar bloques markdown si existen
        if let jsonStart = trimmed.range(of: "```json") {
            if let jsonEnd = trimmed.range(of: "```", range: jsonStart.upperBound..<trimmed.endIndex) {
                jsonStr = String(trimmed[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Verificar que sea JSON valido
        guard jsonStr.hasPrefix("{"), jsonStr.hasSuffix("}") else { return nil }
        
        if let data = jsonStr.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let toolName = dict["tool"] as? String,
           let args = dict["args"] as? [String: String] {
            return (toolName, args)
        }
        return nil
    }
    
    private func registerDefaultTools() {
        register(tool: Tool(
            name: "open_app",
            description: "Abre una aplicacion por su nombre (ej: Safari, Xcode, Terminal)",
            parameters: ["app_name": "String - nombre de la app"],
            execute: { args in
                guard let appName = args["app_name"] else { return "❌ Falta app_name" }
                let ws = NSWorkspace.shared
                
                // 1. Buscar por bundle ID exacto
                if appName.contains(".") {
                    if let url = ws.urlForApplication(withBundleIdentifier: appName) {
                        ws.open(url)
                        return "✅ App '\(appName)' abierta."
                    }
                }
                
                // 2. Buscar por nombre con prefijo com.apple.
                if let url = ws.urlForApplication(withBundleIdentifier: "com.apple." + appName) {
                    ws.open(url)
                    return "✅ App '\(appName)' abierta."
                }
                
                // 3. Verificar si existe con mdfind antes de intentar abrir
                let checkTask = Process()
                checkTask.launchPath = "/usr/bin/mdfind"
                checkTask.arguments = ["kMDItemDisplayName == '" + appName + "'"]
                let checkPipe = Pipe()
                checkTask.standardOutput = checkPipe
                try? checkTask.run()
                checkTask.waitUntilExit()
                let found = String(data: checkPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                if found.isEmpty {
                    // Ultimo intento: open -a con captura de error
                    let errPipe = Pipe()
                    let task = Process()
                    task.launchPath = "/usr/bin/open"
                    task.arguments = ["-a", appName]
                    task.standardError = errPipe
                    try? task.run()
                    task.waitUntilExit()
                    let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    if err.contains("Unable to find") || task.terminationStatus != 0 {
                        return "❌ App '\(appName)' no encontrada en tu Mac. No esta instalada."
                    }
                    return "✅ App '\(appName)' abierta."
                }
                
                // Si mdfind la encontro, abrirla
                ws.open(URL(fileURLWithPath: found))
                return "✅ App '\(appName)' abierta."
            }
        ))
        
        register(tool: Tool(
            name: "open_url",
            description: "Abre una URL en el navegador predeterminado",
            parameters: ["url": "String - URL completa"],
            execute: { args in
                guard let urlStr = args["url"], let url = URL(string: urlStr) else { return "❌ URL invalida" }
                NSWorkspace.shared.open(url)
                return "✅ URL '\(urlStr)' abierta."
            }
        ))
        
        register(tool: Tool(
            name: "write_note",
            description: "Guarda una nota de texto en ~/Documents/MACRON/Notes",
            parameters: ["title": "String", "content": "String"],
            execute: { args in
                guard let title = args["title"], let content = args["content"] else { return "❌ Faltan parametros" }
                let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents/MACRON/Notes")
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let file = dir.appendingPathComponent("\(title).md")
                let body = "# \(title)\n\n\(content)\n\n---\nCreado por MACRON Agent"
                try? body.write(to: file, atomically: true, encoding: .utf8)
                return "✅ Nota '\(title)' guardada."
            }
        ))
        
        register(tool: Tool(
            name: "run_shell",
            description: "Ejecuta un comando shell de forma segura (whitelist basica)",
            parameters: ["command": "String - comando shell"],
            execute: { args in
                guard let cmd = args["command"] else { return "❌ Falta command" }
                let whitelist = ["ls", "pwd", "echo", "cat", "grep", "find", "git status", "swift --version"]
                guard whitelist.contains(where: { cmd.hasPrefix($0) }) else { return "❌ Comando no permitido por seguridad." }
                let task = Process()
                task.launchPath = "/bin/zsh"
                task.arguments = ["-c", cmd]
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                try? task.run()
                task.waitUntilExit()
                return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "(sin salida)"
            }
        ))
        
        register(tool: Tool(
            name: "set_reminder",
            description: "Crea un recordatorio local usando UserNotifications",
            parameters: ["title": "String", "body": "String", "seconds": "Int - segundos desde ahora"],
            execute: { args in
                guard let title = args["title"], let body = args["body"], let secStr = args["seconds"], let seconds = Int(secStr) else { return "❌ Parametros invalidos" }
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { _ in }
                return "✅ Recordatorio '\(title)' en \(seconds)s."
            }
        ))
        
        register(tool: Tool(
            name: "get_context",
            description: "Obtiene el contexto actual de lo que el usuario esta viendo",
            parameters: [:],
            execute: { _ in VoiceContextEngine.shared.currentContext.enrichedPrompt }
        ))
        
        register(tool: Tool(
            name: "search_spotlight",
            description: "Busca archivos en Spotlight por nombre",
            parameters: ["query": "String - termino de busqueda"],
            execute: { args in
                guard let query = args["query"] else { return "❌ Falta query" }
                let mq = NSMetadataQuery()
                mq.predicate = NSPredicate(format: "kMDItemDisplayName CONTAINS[cd] %@", query)
                mq.searchScopes = [NSMetadataQueryLocalComputerScope]
                mq.start()
                Thread.sleep(forTimeInterval: 1.0)
                var results: [String] = []
                for i in 0..<min(mq.resultCount, 5) {
                    if let item = mq.result(at: i) as? NSMetadataItem, let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                        results.append(path)
                    }
                }
                mq.stop()
                return results.isEmpty ? "🔍 Sin resultados para '\(query)'." : "🔍 Resultados:\n" + results.joined(separator: "\n")
            }
        ))
    }
}
