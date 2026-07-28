import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

@main
struct MACRONApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("MACRON") {
                Button("Activar Brain") { MACRONBrain.shared.boot() }
                Button("Detener Brain") { MACRONBrain.shared.shutdown() }
                Divider()
                Button("Modo Focus") { _ = WindowManagerAI.shared.focusMode() }
                Button("Maximizar Ventana") { _ = WindowManagerAI.shared.maximizeActive() }
            }
        }
    }
}
