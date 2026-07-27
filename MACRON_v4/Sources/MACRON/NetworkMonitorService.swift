import Foundation

class NetworkMonitorService: ObservableObject {
    static let shared = NetworkMonitorService()
    @Published var activeConnections: [String] = []
    @Published var totalTraffic = "0 KB"
    
    func scanConnections() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        task.arguments = ["-i", "-n", "-P"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let lines = output.components(separatedBy: .newlines).filter { $0.contains("ESTABLISHED") }
        var apps: [String] = []
        for line in lines {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count > 0, !apps.contains(parts[0]) {
                apps.append(parts[0])
            }
        }
        activeConnections = apps.sorted()
    }
    
    func getTrafficStats() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/netstat")
        task.arguments = ["-ib"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let lines = output.components(separatedBy: .newlines)
        for line in lines where line.contains("en0") {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count > 10 {
                let rx = (Int(parts[6]) ?? 0) / 1024
                let tx = (Int(parts[9]) ?? 0) / 1024
                totalTraffic = "RX: " + String(rx) + " KB | TX: " + String(tx) + " KB"
            }
        }
    }
}
