import Foundation

class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsageMB: Double = 0.0
    @Published var batteryLevel: Int = 100
    @Published var isCharging: Bool = false
    
    private var timer: Timer?
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateStats()
        }
        updateStats()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
    }
    
    private func updateStats() {
        // CPU
        if let cpuStr = shell("top -l 2 | grep 'CPU usage' | tail -1 | awk '{print $3}' | sed 's/%//'"),
           let cpu = Double(cpuStr) {
            DispatchQueue.main.async { self.cpuUsage = cpu }
        }
        // Memory
        if let memStr = shell("vm_stat | grep 'Pages active' | awk '{print $3}' | sed 's/\\.//'"),
           let pages = Double(memStr) {
            let mb = pages * 4096 / 1024 / 1024
            DispatchQueue.main.async { self.memoryUsageMB = mb }
        }
        // Battery
        if let battStr = shell("pmset -g batt | grep -Eo '\\d+%' | head -1 | sed 's/%//'"),
           let batt = Int(battStr) {
            DispatchQueue.main.async { self.batteryLevel = batt }
        }
        if let powerStr = shell("pmset -g batt | grep 'AC Power'") {
            DispatchQueue.main.async { self.isCharging = !powerStr.isEmpty }
        }
    }
    
    private func shell(_ command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", command]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
