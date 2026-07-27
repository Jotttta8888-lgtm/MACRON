import Foundation

class FocusModeService: ObservableObject {
    static let shared = FocusModeService()
    @Published var currentFocus = "Ninguno"
    @Published var isDoNotDisturb = false
    
    func startMonitoring() {
        checkFocusStatus()
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.checkFocusStatus()
        }
    }
    
    func checkFocusStatus() {
        if let output = shell("defaults -currentHost read ~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturb 2>/dev/null") {
            isDoNotDisturb = output.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
        }
        currentFocus = isDoNotDisturb ? "No Molestar" : "Ninguno"
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
        return String(data: data, encoding: .utf8)
    }
}
