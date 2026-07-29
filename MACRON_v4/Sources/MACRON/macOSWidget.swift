import Foundation

public final class macOSWidget: @unchecked Sendable {
    public static let shared = macOSWidget()
    private init() {}
    
    public struct WidgetData: Sendable {
        public let brainStatus: String
        public let focusActive: Bool
        public let focusRemaining: String
        public let cpuUsage: Double
        public let memoryUsage: Double
        public let unreadEmails: Int
        public let nextEvent: String
        public let quickActions: [String]
    }
    
    public func currentData() -> WidgetData {
        let health = SystemDiagnostics.shared.fullDiagnostic()
        let focus = FocusSessionsPro.shared
        
        return WidgetData(
            brainStatus: "Activo",
            focusActive: focus.isActive,
            focusRemaining: focus.isActive ? formatTime(focus.remainingTime()) : "Sin sesion",
            cpuUsage: health.cpuUsage,
            memoryUsage: health.memoryUsage,
            unreadEmails: 0,
            nextEvent: "Hoy 15:00 - Reunion",
            quickActions: ["Focus 25m", "Diagnostico", "Buscar", "Modo Noche"]
        )
    }
    
    public func generateWidgetJSON() -> String {
        let data = currentData()
        var lines: [String] = []
        lines.append("{")
        lines.append("  \"brain_status\": \"" + data.brainStatus + "\",")
        lines.append("  \"focus_active\": " + (data.focusActive ? "true" : "false") + ",")
        lines.append("  \"focus_remaining\": \"" + data.focusRemaining + "\",")
        lines.append("  \"cpu_usage\": " + String(format: "%.1f", data.cpuUsage) + ",")
        lines.append("  \"memory_usage\": " + String(format: "%.1f", data.memoryUsage) + ",")
        lines.append("  \"next_event\": \"" + data.nextEvent + "\",")
        lines.append("  \"quick_actions\": [" + data.quickActions.map { "\"" + $0 + "\"" }.joined(separator: ", ") + "]")
        lines.append("}")
        return lines.joined(separator: "\n")
    }
    
    public func exportForWidget() {
        let json = generateWidgetJSON()
        let path = NSHomeDirectory() + "/Documents/MACRON/widget_data.json"
        try? json.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(m) + "m " + String(s) + "s"
    }
}
