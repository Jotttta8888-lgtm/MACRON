import Foundation

class CrashRecoveryService: NSObject {
    static let shared = CrashRecoveryService()
    private var timer: Timer?
    private var consecutiveFailures = 0
    private let maxFailures = 3
    private let scriptPath = NSHomeDirectory() + "/Documents/MACRON/start_macron.sh"
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.checkBackend()
        }
        print("[CrashRecovery] Vigía activo cada 10s")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkBackend() {
        guard FileManager.default.fileExists(atPath: scriptPath) else { return }
        let task = URLSession.shared.dataTask(with: URL(string: "http://localhost:5001/api/health")!) { _, response, _ in
            DispatchQueue.main.async {
                if let r = response as? HTTPURLResponse, r.statusCode == 200 {
                    if self.consecutiveFailures > 0 {
                        self.consecutiveFailures = 0
                        NotificationService.shared.send(title: "MACRON", body: "Backend recuperado")
                    }
                } else {
                    self.consecutiveFailures += 1
                    print("[CrashRecovery] Fallo #\(self.consecutiveFailures)")
                    if self.consecutiveFailures >= self.maxFailures {
                        self.restartBackend()
                        self.consecutiveFailures = 0
                    }
                }
            }
        }
        task.resume()
    }
    
    private func restartBackend() {
        print("[CrashRecovery] Reiniciando backend...")
        NotificationService.shared.send(title: "MACRON", body: "Backend caído. Reiniciando...")
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath]
        task.environment = ProcessInfo.processInfo.environment
        do {
            try task.run()
        } catch {
            print("[CrashRecovery] Error reiniciando: \(error)")
        }
    }
}
