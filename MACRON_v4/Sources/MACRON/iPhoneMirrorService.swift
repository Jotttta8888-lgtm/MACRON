import Foundation

class iPhoneMirrorService: ObservableObject {
    static let shared = iPhoneMirrorService()
    @Published var mirroredNotifications: [MirroredNotification] = []
    @Published var isMirroringEnabled = false
    
    struct MirroredNotification: Identifiable {
        let id = UUID()
        let appName: String
        let title: String
        let body: String
        let timestamp: Date
    }
    
    func enableMirroring() {
        isMirroringEnabled = true
        NotificationService.shared.send(title: "MACRON Mirror", body: "Espejo de notificaciones activado")
    }
    
    func disableMirroring() {
        isMirroringEnabled = false
    }
    
    func simulateNotification(appName: String, title: String, body: String) {
        guard isMirroringEnabled else { return }
        let notif = MirroredNotification(appName: appName, title: title, body: body, timestamp: Date())
        mirroredNotifications.insert(notif, at: 0)
        if mirroredNotifications.count > 50 {
            mirroredNotifications.removeLast()
        }
        NotificationService.shared.send(title: appName, body: title + ": " + body)
    }
    
    func replyToMessage(app: String, message: String) {
        let script = "display notification \\\"Respuesta enviada\\\" with title \\\"\\(app)\\\""
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }
}
