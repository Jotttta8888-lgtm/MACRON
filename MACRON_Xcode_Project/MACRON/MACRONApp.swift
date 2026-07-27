import SwiftUI
import AppKit
import UserNotifications

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
        .windowStyle(.hiddenTitleBar)
        .commands { MacronCommands() }
        
        MenuBarExtra("MACRON", systemImage: api.isOnline ? "cpu" : "cpu.fill") {
            MenuBarView().environmentObject(api)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        NSWindow.allowsAutomaticWindowTabbing = false
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
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
    static let showCalendar = Notification.Name("showCalendar")
}
