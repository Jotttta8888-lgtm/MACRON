import Foundation

/// Servicio centralizado para abrir aplicaciones.
public final class AppLauncher: @unchecked Sendable {
    public static let shared = AppLauncher()
    private init() {}

    private let appMap: [String: String] = [
        "safari": "Safari", "chrome": "Google Chrome", "firefox": "Firefox",
        "arc": "Arc", "brave": "Brave Browser", "edge": "Microsoft Edge",
        "terminal": "Terminal", "vscode": "Visual Studio Code", "code": "Visual Studio Code",
        "xcode": "Xcode", "github": "GitHub Desktop",
        "mail": "Mail", "correo": "Mail", "notes": "Notes", "notas": "Notes",
        "calendar": "Calendar", "calendario": "Calendar",
        "calculator": "Calculator", "calculadora": "Calculator",
        "reminders": "Reminders", "recordatorios": "Reminders",
        "music": "Music", "musica": "Music", "spotify": "Spotify",
        "photos": "Photos", "fotos": "Photos", "obs": "OBS Studio",
        "quicktime": "QuickTime Player", "whatsapp": "WhatsApp",
        "telegram": "Telegram", "discord": "Discord", "slack": "Slack",
        "zoom": "zoom.us", "facetime": "FaceTime", "messages": "Messages",
        "mensajes": "Messages", "chatgpt": "ChatGPT", "claude": "Claude",
        "perplexity": "Perplexity", "notion": "Notion",
        "photoshop": "Adobe Photoshop 2026", "premiere": "Adobe Premiere Pro 2026",
        "after effects": "Adobe After Effects 2026", "illustrator": "Adobe Illustrator",
        "figma": "Figma", "blender": "Blender", "finder": "Finder",
        "explorador": "Finder", "activity monitor": "Activity Monitor",
        "monitoreo": "Activity Monitor", "system preferences": "System Preferences",
        "preferencias": "System Preferences",
    ]

    public func openApp(keyword: String, orchestrator: AgentOrchestrator) -> String {
        let lower = keyword.lowercased().trimmingCharacters(in: .whitespaces)
        if let appName = appMap[lower] {
            return executeOpen(appName: appName, orchestrator: orchestrator)
        }
        for (key, appName) in appMap {
            if lower.contains(key) { return executeOpen(appName: appName, orchestrator: orchestrator) }
        }
        return "❌ No reconozco esa app. Apps: \(appMap.keys.sorted().joined(separator: ", "))"
    }

    private func executeOpen(appName: String, orchestrator: AgentOrchestrator) -> String {
        let res = orchestrator.execute(toolName: "open_app", arguments: ["app_name": appName])
        if res.contains("❌") || res.contains("no encontrada") {
            return "❌ No pude abrir \(appName). ¿Esta instalada?"
        }
        return "\(appName) abierto."
    }

    public func listApps() -> String {
        let apps = appMap.keys.sorted()
        var lines: [String] = ["📱 Apps (\(apps.count)):"]
        stride(from: 0, to: apps.count, by: 6).forEach { i in
            lines.append("  " + apps[i..<min(i+6, apps.count)].joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }
}
