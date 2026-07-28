import Foundation
import AppKit

/// SmartHomeAI (FF)
/// Controla dispositivos HomeKit via AppleScript a traves de la app Casa.
/// Detecta contexto (pelicula, trabajo, noche) y ajusta escenas.
public final class SmartHomeAI: @unchecked Sendable {
    public static let shared = SmartHomeAI()
    
    private let sceneShortcuts: [String: String] = [
        "cine": "Modo Cine", "movie": "Modo Cine", "pelicula": "Modo Cine",
        "trabajo": "Modo Trabajo", "work": "Modo Trabajo", "focus": "Modo Trabajo",
        "noche": "Modo Noche", "night": "Modo Noche", "dormir": "Modo Noche",
        "descanso": "Modo Descanso", "relax": "Modo Descanso",
        "apagado": "Apagar Todo", "off": "Apagar Todo", "apaga todo": "Apagar Todo",
        "encendido": "Encender Todo", "on": "Encender Todo"
    ]
    
    private init() {}
    
    /// Ejecuta un comando natural via AppleScript/Atajos
    public func executeCommand(_ command: String) -> String {
        let lower = command.lowercased()
        
        // Buscar escena
        for (trigger, shortcutName) in sceneShortcuts {
            if lower.contains(trigger) {
                return runShortcut(named: shortcutName)
            }
        }
        
        // Control individual por AppleScript
        if lower.contains("luz") || lower.contains("light") {
            let action = lower.contains("apaga") || lower.contains("off") ? "false" : "true"
            let room = extractRoom(from: lower) ?? "Sala"
            return runAppleScript("""
                tell application "Home"
                    set theValue to \(action)
                    set value of accessory "\(room)" to theValue
                end tell
            """) ?? "⚠️ No se pudo controlar la luz. Asegurate de que la app Casa tenga accesorios nombrados."
        }
        
        return "❌ No entendi el comando HomeKit. Prueba: 'modo cine', 'apaga la luz', 'modo noche'."
    }
    
    /// Detecta contexto y sugiere escena automatica
    public func autoScene() -> String {
        let ctx = VoiceContextEngine.shared.currentContext
        let app = ctx.appName.lowercased()
        let hour = Calendar.current.component(.hour, from: Date())
        
        if app.contains("netflix") || app.contains("prime") || app.contains("disney") {
            return executeCommand("modo cine")
        } else if app.contains("xcode") || app.contains("code") {
            return executeCommand("modo trabajo")
        } else if hour >= 22 || hour <= 6 {
            return executeCommand("modo noche")
        }
        return "🤖 No detecte contexto especial para HomeKit."
    }
    
    // MARK: - Private
    
    private func runShortcut(named: String) -> String {
        let task = Process()
        task.launchPath = "/usr/bin/shortcuts"
        task.arguments = ["run", named]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if task.terminationStatus == 0 {
                return "✅ Escena '\(named)' activada via Atajos."
            }
            return "⚠️ Atajo '\(named)' no encontrado. Crealo en la app Atajos con acciones HomeKit. Error: \(output)"
        } catch {
            return "❌ Error ejecutando atajo: \(error.localizedDescription)"
        }
    }
    
    private func runAppleScript(_ script: String) -> String? {
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let output = appleScript.executeAndReturnError(&error)
            if let error = error { return "❌ AppleScript error: \(error)" }
            return output.stringValue
        }
        return nil
    }
    
    private func extractRoom(from text: String) -> String? {
        let rooms = ["sala", "cocina", "habitacion", "bano", "estudio", "comedor", "dormitorio", "garaje"]
        for room in rooms { if text.contains(room) { return room.capitalized } }
        return nil
    }
}
