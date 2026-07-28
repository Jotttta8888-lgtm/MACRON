import Foundation

public final class SystemDiagnostics: @unchecked Sendable {
    public static let shared = SystemDiagnostics()
    
    public struct SystemHealth: Sendable {
        public let cpuUsage: Double
        public let memoryUsage: Double
        public let diskUsage: Double
        public let temperature: Double?
        public let uptime: TimeInterval
        public let batteryLevel: Double?
        public let topProcesses: [ProcessInfo]
        public let recommendations: [String]
    }
    
    public struct ProcessInfo: Sendable {
        public let name: String
        public let pid: Int
        public let cpuPercent: Double
        public let memoryMB: Double
    }
    
    private init() {}
    
    public func fullDiagnostic() -> SystemHealth {
        return SystemHealth(
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            diskUsage: getDiskUsage(),
            temperature: getTemperature(),
            uptime: getUptime(),
            batteryLevel: getBatteryLevel(),
            topProcesses: getTopProcesses(),
            recommendations: generateRecommendations()
        )
    }
    
    public func quickReport() -> String {
        let health = fullDiagnostic()
        var lines: [String] = []
        lines.append("DIAGNOSTICO MACRON")
        lines.append("CPU: " + String(format: "%.1f", health.cpuUsage) + "%")
        lines.append("RAM: " + String(format: "%.1f", health.memoryUsage) + "%")
        lines.append("Disco: " + String(format: "%.1f", health.diskUsage) + "%")
        if let temp = health.temperature { lines.append("Temp: " + String(format: "%.1f", temp) + "C") }
        if let batt = health.batteryLevel { lines.append("Bateria: " + String(format: "%.0f", batt) + "%") }
        lines.append("Uptime: " + formatUptime(health.uptime))
        lines.append("Top Procesos:")
        for proc in health.topProcesses.prefix(5) {
            lines.append("  " + proc.name + ": " + String(format: "%.1f", proc.cpuPercent) + "% CPU, " + String(format: "%.0f", proc.memoryMB) + "MB")
        }
        if !health.recommendations.isEmpty {
            lines.append("Recomendaciones:")
            for rec in health.recommendations { lines.append("  - " + rec) }
        } else {
            lines.append("Sistema saludable")
        }
        return lines.joined(separator: "\n")
    }
    
    private func getCPUUsage() -> Double {
        var loadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &loadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0.0 }
        let total = Double(loadInfo.cpu_ticks.0 + loadInfo.cpu_ticks.1 + loadInfo.cpu_ticks.2)
        let user = Double(loadInfo.cpu_ticks.0)
        return total > 0 ? (user / total) * 100.0 : 0.0
    }
    
    private func getMemoryUsage() -> Double {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0.0 }
        let used = Double(info.active_count + info.inactive_count + info.wire_count) * Double(vm_page_size)
        let total = Double(info.active_count + info.inactive_count + info.wire_count + info.free_count) * Double(vm_page_size)
        return total > 0 ? (used / total) * 100.0 : 0.0
    }
    
    private func getDiskUsage() -> Double {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = (attrs[.systemSize] as? NSNumber)?.doubleValue ?? 1
            let free = (attrs[.systemFreeSize] as? NSNumber)?.doubleValue ?? 0
            return ((total - free) / total) * 100.0
        } catch { return 0.0 }
    }
    
    private func getTemperature() -> Double? { return nil }
    
    private func getUptime() -> TimeInterval {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.size
        sysctlbyname("kern.boottime", &boottime, &size, nil, 0)
        let bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
        return Date().timeIntervalSince(bootDate)
    }
    
    private func getBatteryLevel() -> Double? {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        guard let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else { return nil }
        let pattern = "(\\d+)%;"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output) else { return nil }
        return Double(output[range])
    }
    
    private func getTopProcesses() -> [ProcessInfo] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-arcwwwxo", "pid,pcpu,pmem,comm"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        guard let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else { return [] }
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: .newlines).dropFirst()
        for line in lines.prefix(10) {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 4,
                  let pid = Int(parts[0]),
                  let cpu = Double(parts[1]),
                  let mem = Double(parts[2]) else { continue }
            let name = parts.dropFirst(3).joined(separator: " ")
            processes.append(ProcessInfo(name: name, pid: pid, cpuPercent: cpu, memoryMB: mem))
        }
        return processes
    }
    
    private func generateRecommendations() -> [String] {
        var recs: [String] = []
        if getCPUUsage() > 80 { recs.append("CPU alto. Cierra apps pesadas.") }
        if getMemoryUsage() > 85 { recs.append("RAM casi llena. Reinicia o cierra tabs.") }
        if getDiskUsage() > 90 { recs.append("Disco casi lleno. Limpia Downloads.") }
        if getDiskUsage() > 80 { recs.append("Considera vaciar la papelera.") }
        return recs
    }
    
    private func formatUptime(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let mins = (Int(interval) % 3600) / 60
        if days > 0 { return String(days) + "d " + String(hours) + "h " + String(mins) + "m" }
        return String(hours) + "h " + String(mins) + "m"
    }
}
