import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        DispatchQueue.main.async {
            NSApp.keyWindow?.makeKey()
        }
    }
}

@main
struct MACRONApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var api = MacronAPIClient.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(api)
                .frame(minWidth: 1100, minHeight: 750)
        }
        .windowStyle(.automatic)
        .commands { MacronCommands() }
    }
}

struct MacronCommands: Commands {
    var body: some Commands {
        CommandMenu("MACRON") {
            Button("Iniciar Backend") {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Documents/MACRON/start_macron.sh"))
            }.keyboardShortcut("r", modifiers: .command)
            Divider()
            Button("Preferencias...") {
                NotificationCenter.default.post(name: .showSettings, object: nil)
            }.keyboardShortcut(",", modifiers: .command)
        }
    }
}

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
    static let showChat = Notification.Name("showChat")
    static let showDashboard = Notification.Name("showDashboard")
    static let showCalendar = Notification.Name("showCalendar")
}
