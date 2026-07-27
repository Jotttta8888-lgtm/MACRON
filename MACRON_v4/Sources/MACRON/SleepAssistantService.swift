import Foundation
import AppKit

class SleepAssistantService: ObservableObject {
    static let shared = SleepAssistantService()
    @Published var isSleepModeActive = false
    
    func activateSleepMode() {
        isSleepModeActive = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", "tell application \"System Events\" to key code 145"]
        try? task.run()
        NotificationService.shared.send(title: "MACRON Sleep", body: "Modo sueno activado")
    }
    
    func deactivateSleepMode() {
        isSleepModeActive = false
        NotificationService.shared.send(title: "MACRON Sleep", body: "Modo sueno desactivado")
    }
    
    func playWhiteNoise() {
        if let url = URL(string: "https://www.youtube.com/watch?v=jX6kn9_U8qk") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func scheduleShutdown(minutes: Int) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/shutdown")
        task.arguments = ["-s", "+" + String(minutes)]
        try? task.run()
        NotificationService.shared.send(title: "MACRON Sleep", body: "Apagado programado en " + String(minutes) + " minutos")
    }
}
