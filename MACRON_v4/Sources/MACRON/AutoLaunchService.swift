import Foundation

class AutoLaunchService {
    static let shared = AutoLaunchService()
    private let launchAgentPath = NSHomeDirectory() + "/Library/LaunchAgents/com.macron.autostart.plist"
    private let appPath = "/Applications/MACRON.app"
    
    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentPath)
    }
    
    func setEnabled(_ enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }
    
    private func enable() {
        let plist: [String: Any] = [
            "Label": "com.macron.autostart",
            "ProgramArguments": ["/usr/bin/open", appPath],
            "RunAtLoad": true,
            "KeepAlive": false,
            "StandardOutPath": NSHomeDirectory() + "/Documents/MACRON/logs/launchagent.out",
            "StandardErrorPath": NSHomeDirectory() + "/Documents/MACRON/logs/launchagent.err"
        ]
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: URL(fileURLWithPath: launchAgentPath))
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["load", launchAgentPath]
            try task.run()
            task.waitUntilExit()
            print("[AutoLaunch] Activado para login")
        } catch {
            print("[AutoLaunch] Error: \(error)")
        }
    }
    
    private func disable() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["unload", launchAgentPath]
        try? task.run()
        task.waitUntilExit()
        try? FileManager.default.removeItem(atPath: launchAgentPath)
        print("[AutoLaunch] Desactivado")
    }
}
