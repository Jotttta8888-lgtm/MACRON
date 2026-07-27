import Foundation
import AppKit

class ProductivityTracker: ObservableObject {
    static let shared = ProductivityTracker()
    @Published var todayReport = "Sin datos"
    @Published var currentApp = "Ninguna"
    
    private var usageLog: [String: TimeInterval] = [:]
    private var currentAppStart: Date?
    private let logPath = NSHomeDirectory() + "/Documents/MACRON/productivity_log.json"
    private var timer: Timer?
    
    func startTracking() {
        NotificationCenter.default.addObserver(self, selector: #selector(appChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.saveLog()
            self.generateReport()
        }
        appChanged()
    }
    
    @objc private func appChanged() {
        if let start = currentAppStart {
            let duration = Date().timeIntervalSince(start)
            usageLog[currentApp, default: 0] += duration
        }
        if let app = NSWorkspace.shared.frontmostApplication {
            currentApp = app.localizedName ?? "Desconocida"
        }
        currentAppStart = Date()
    }
    
    private func saveLog() {
        let data = try? JSONSerialization.data(withJSONObject: usageLog, options: .prettyPrinted)
        try? data?.write(to: URL(fileURLWithPath: logPath))
    }
    
    private func generateReport() {
        let sorted = usageLog.sorted { $0.value > $1.value }
        let lines = sorted.prefix(5).map { app, time in
            let mins = Int(time / 60)
            return app + ": " + String(mins) + " min"
        }
        todayReport = lines.joined(separator: "\n")
    }
    
    func getReport() -> String {
        generateReport()
        return todayReport
    }
}
