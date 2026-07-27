import Foundation
import IOKit.ps

class BatteryOptimizerService: ObservableObject {
    static let shared = BatteryOptimizerService()
    @Published var batteryLevel = 100
    @Published var isPowerSaving = false
    
    func getBatteryInfo() -> String {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first else { return "No info" }
        guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else { return "No info" }
        let level = info[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let state = info[kIOPSPowerSourceStateKey as String] as? String ?? "Unknown"
        return "Bateria: \(level)% - \(state)"
    }
    
    func enablePowerSaving() {
        isPowerSaving = true
        let script = "tell application \\\"System Events\\\" to set power saving of preferences to true"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
        NotificationService.shared.send(title: "MACRON Battery", body: "Modo ahorro activado")
    }
    
    func disablePowerSaving() {
        isPowerSaving = false
        let script = "tell application \\\"System Events\\\" to set power saving of preferences to false"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }
    
    func checkBatteryAlert() {
        let info = getBatteryInfo()
        if info.contains("20%") || info.contains("10%") {
            NotificationService.shared.send(title: "MACRON Battery", body: "Bateria baja: " + info)
        }
    }
}
