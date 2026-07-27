import Foundation

class HomeKitBridge: ObservableObject {
    static let shared = HomeKitBridge()
    @Published var isReady = false
    @Published var lastAction = "Sin acciones"
    
    func setup() {
        isReady = true
        print("[HomeKit] Puente listo (via AppleScript)")
    }
    
    func runAppleScript(_ source: String) -> String? {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&errorInfo)
        if let error = errorInfo {
            print("[HomeKit] Error: " + String(describing: error))
            return nil
        }
        return result.stringValue
    }
    
    func toggleLight(named: String, on: Bool) {
        let state = on ? "true" : "false"
        let script = """
        tell application "Home"
            set targetLight to first accessory whose name contains "\(named)"
            set value of characteristic "On" of targetLight to \(state)
            return "OK"
        end tell
        """
        if runAppleScript(script) != nil {
            lastAction = named + (on ? " encendida" : " apagada")
            NotificationService.shared.send(title: "HomeKit", body: lastAction)
        }
    }
    
    func setThermostat(named: String, temp: Double) {
        let script = """
        tell application "Home"
            set targetThermo to first accessory whose name contains "\(named)"
            set value of characteristic "Target Temperature" of targetThermo to \(temp)
            return "OK"
        end tell
        """
        if runAppleScript(script) != nil {
            lastAction = "Termostato " + named + " a " + String(temp) + "C"
            NotificationService.shared.send(title: "HomeKit", body: lastAction)
        }
    }
    
    func activateScene(_ name: String) {
        let script = """
        tell application "Home"
            set targetScene to first scene whose name is "\(name)"
            execute targetScene
            return "OK"
        end tell
        """
        if runAppleScript(script) != nil {
            lastAction = "Escena activada: " + name
            NotificationService.shared.send(title: "HomeKit", body: lastAction)
        }
    }
}
