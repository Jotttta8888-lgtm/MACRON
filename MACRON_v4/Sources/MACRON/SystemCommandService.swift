import Foundation

public final class SystemCommandService: @unchecked Sendable {
    public static let shared = SystemCommandService()
    private init() {}

    public func setVolume(level: Int) -> String {
        let clamped = max(0, min(100, level))
        let script = "set volume output volume \(clamped)"
        return runAppleScript(script) ?? "❌ Error ajustando volumen"
    }

    public func mute() -> String {
        _ = runAppleScript("set volume with output muted")
        return "🔇 Silenciado"
    }

    public func unmute() -> String {
        _ = runAppleScript("set volume without output muted")
        return "🔊 Sonido activado"
    }

    public func setBrightness(level: Int) -> String {
        let clamped = max(0, min(100, level))
        return "💡 Brillo \(clamped)% (placeholder - requiere IOKit)"
    }

    public func toggleWiFi() -> String {
        let script = "do shell script \"networksetup -setairportpower en0 on\""
        return runAppleScript(script) ?? "📡 WiFi activado"
    }

    public func turnOffWiFi() -> String {
        let script = "do shell script \"networksetup -setairportpower en0 off\""
        return runAppleScript(script) ?? "📡 WiFi desactivado"
    }

    public func toggleBluetooth() -> String {
        let script = "do shell script \"blueutil --power toggle\""
        return runAppleScript(script) ?? "🔵 Bluetooth toggled"
    }

    public func toggleDoNotDisturb() -> String {
        return "🔕 No Molestar (placeholder - requiere Focus API)"
    }

    public func screenshot() -> String {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let filename = "screenshot_\(Int(Date().timeIntervalSince1970)).png"
        let path = desktop.appendingPathComponent(filename).path
        let script = "do shell script \"screencapture -x '\(path)'\""
        return runAppleScript(script) ?? "📸 Screenshot guardado"
    }

    public func sleepMac() -> String {
        _ = runAppleScript("tell application \"System Events\" to sleep")
        return "💤 Reposando..."
    }

    public func restartMac() -> String { return "🔄 Reinicio (requiere confirmacion)" }
    public func shutdownMac() -> String { return "⛔ Apagado (requiere confirmacion)" }

    public func emptyTrash() -> String {
        return runAppleScript("tell application \"Finder\" to empty trash") ?? "🗑️ Papelera vaciada"
    }

    public func lockScreen() -> String {
        _ = runAppleScript("tell application \"System Events\" to keystroke \"q\" using {command down, control down}")
        return "🔒 Pantalla bloqueada"
    }

    private func runAppleScript(_ script: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch { return nil }
    }
}
