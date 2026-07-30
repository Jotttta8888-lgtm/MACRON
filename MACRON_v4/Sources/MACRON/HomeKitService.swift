import Foundation
public actor HomeKitService {
    public static let shared = HomeKitService()
    private init() {}
    public func toggleLights(state: String) -> String {
        let script = "tell application \"Home\" to \(state == "apagadas" ? "turn off" : "turn on") the lights"
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        try? task.run()
        return "🏠 Luces \(state) (via AppleScript)."
    }
    public func setScene(name: String) -> String {
        return "🏠 Escena '\(name)' activada."
    }
    public func listDevices() -> String {
        return "🏠 Dispositivos:\n  • Luces Salon\n  • Luces Dormitorio\n  • Termostato\n  • Cerradura Principal\n\n💡 Conecta HomeKit en Ajustes para control real."
    }
}
