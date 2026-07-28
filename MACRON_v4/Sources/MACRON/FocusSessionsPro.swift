import Foundation
import AppKit

public final class FocusSessionsPro: @unchecked Sendable {
    public static let shared = FocusSessionsPro()
    
    public enum SessionType: String, CaseIterable {
        case pomodoro = "Pomodoro (25 min)"
        case deepWork = "Deep Work (90 min)"
        case quickFocus = "Quick Focus (15 min)"
        case custom = "Personalizado"
    }
    
    public private(set) var isActive = false
    public private(set) var currentSession: SessionType?
    public private(set) var startTime: Date?
    public private(set) var distractionsBlocked: [String] = []
    
    private var timer: Timer?
    private let distractionApps = ["YouTube", "TikTok", "Instagram", "Twitter", "Reddit", "Netflix", "Discord", "Steam"]
    private var originalDNDState = false
    
    private init() {}
    
    public func startSession(type: SessionType, duration: TimeInterval? = nil) {
        guard !isActive else { return }
        isActive = true
        currentSession = type
        startTime = Date()
        
        let duration = duration ?? sessionDuration(for: type)
        originalDNDState = isDNDEnabled()
        setDND(enabled: true)
        blockDistractionApps()
        
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.endSession()
        }
        
        NotificationService.shared.send(
            title: "Focus Session Iniciada",
            body: type.rawValue + ". Distractiones bloqueadas."
        )
    }
    
    public func endSession() {
        guard isActive else { return }
        isActive = false
        timer?.invalidate()
        timer = nil
        setDND(enabled: originalDNDState)
        unblockDistractionApps()
        
        let duration = Date().timeIntervalSince(startTime ?? Date())
        let minutes = Int(duration / 60)
        
        NotificationService.shared.send(
            title: "Focus Session Completada",
            body: "Trabajaste " + String(minutes) + " minutos enfocado."
        )
        
        saveSessionHistory(type: currentSession?.rawValue ?? "Unknown", duration: duration)
        currentSession = nil
        startTime = nil
    }
    
    public func forceStop() {
        endSession()
        NotificationService.shared.send(
            title: "Focus Session Cancelada",
            body: "Session detenida manualmente."
        )
    }
    
    public func remainingTime() -> TimeInterval {
        guard let start = startTime, let type = currentSession else { return 0 }
        let total = sessionDuration(for: type)
        let elapsed = Date().timeIntervalSince(start)
        return max(0, total - elapsed)
    }
    
    public func currentStats() -> String {
        guard isActive, let type = currentSession else { return "No hay session activa" }
        let remaining = remainingTime()
        let mins = Int(remaining / 60)
        let secs = Int(remaining) % 60
        return "Focus: " + type.rawValue + "\nRestante: " + String(mins) + "m " + String(secs) + "s\nApps bloqueadas: " + distractionsBlocked.joined(separator: ", ")
    }
    
    private func sessionDuration(for type: SessionType) -> TimeInterval {
        switch type {
        case .pomodoro: return 25 * 60
        case .deepWork: return 90 * 60
        case .quickFocus: return 15 * 60
        case .custom: return 45 * 60
        }
    }
    
    private func blockDistractionApps() {
        distractionsBlocked.removeAll()
        for app in distractionApps {
            if isAppRunning(app) {
                quitApp(app)
                distractionsBlocked.append(app)
            }
        }
    }
    
    private func unblockDistractionApps() {
        distractionsBlocked.removeAll()
    }
    
    private func isAppRunning(_ name: String) -> Bool {
        let apps = NSWorkspace.shared.runningApplications
        return apps.contains { $0.localizedName?.lowercased() == name.lowercased() }
    }
    
    private func quitApp(_ name: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "quit app " + name]
        try? task.run()
    }
    
    private func isDNDEnabled() -> Bool { return false }
    
    private func setDND(enabled: Bool) {
        let value = enabled ? "true" : "false"
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["write", "com.apple.notificationcenterui", "doNotDisturb", "-bool", value]
        try? task.run()
    }
    
    private func saveSessionHistory(type: String, duration: TimeInterval) {
        let key = "macron_focus_history"
        var history = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
        history.append([
            "type": type,
            "duration": duration,
            "date": ISO8601DateFormatter().string(from: Date())
        ])
        if history.count > 100 { history.removeFirst() }
        UserDefaults.standard.set(history, forKey: key)
    }
    
    public func history() -> [[String: Any]] {
        return UserDefaults.standard.array(forKey: "macron_focus_history") as? [[String: Any]] ?? []
    }
}
