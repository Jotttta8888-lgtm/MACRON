import SwiftUI
import AppKit
import AppIntents
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // SOLO hotkey global. NADA de activate automatico.
        HotkeyService.shared.startMonitoring()
        MenuBarService.shared.setup()
        WritingToolsService.shared.setup()
        ClipboardHistoryService.shared.startMonitoring()
        ProductivityTracker.shared.startTracking()
        HomeKitBridge.shared.setup()
        SmartNotesService.shared.loadNotes()
        PersonalKnowledgeBase.shared.loadIndex()
        FinanceTracker.shared.load()
        WeatherAdvisor.shared.checkWeather()
        GameModeService.shared.startMonitoring()
        LocalWebServer.shared.start()
        CodeSnippetManager.shared.load()
        RSSNewsReader.shared.fetchFeed(url: "https://feeds.bbci.co.uk/news/rss.xml", source: "BBC")
        DigitalWellbeingService.shared.startTracking()
        SystemMonitorService.shared.startMonitoring()
        MeetingAssistantService.shared.startMonitoring()
        VoicePipelineService.shared.setup()
        FocusModeService.shared.startMonitoring()
        PluginSystem.shared.scanPlugins()
        PluginSystem.shared.createExamplePlugin()
        // Todo lo demas desactivado para evitar robos de foco:
        // NotificationService, CrashRecovery, SleepWake, ScreenSharing, WakeWord
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        // VACIO - Nunca forzar ventana al frente
    }
    func applicationWillTerminate(_ notification: Notification) {
        HotkeyService.shared.stopMonitoring()
    }
}

@main
struct MACRONApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var api = MacronAPIClient.shared
    @StateObject private var themeManager = ThemeManager()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var showSearch = false
    @State private var showShortcuts = false
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(api)
                    .environmentObject(themeManager)
                if showSplash {
                    SplashScreenOverlay()
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .sheet(isPresented: $showOnboarding) { OnboardingView(isPresented: $showOnboarding) }
            .sheet(isPresented: $showSearch) { GlobalSearchView(isPresented: $showSearch) }
            .sheet(isPresented: $showShortcuts) { KeyboardShortcutsHelpView(isPresented: $showShortcuts) }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) { showSplash = false }
                }
            }
            .frame(minWidth: 1100, minHeight: 750)
        }
        .commands {
            CommandMenu("MACRON") {
                Button("Buscar (Cmd+K)") { showSearch.toggle() }
                    .keyboardShortcut("k", modifiers: .command)
                Button("Atajos (Cmd+/)") { showShortcuts.toggle() }
                    .keyboardShortcut("/", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let showSettings = Notification.Name("showSettings")
    static let showChat = Notification.Name("showChat")
    static let showDashboard = Notification.Name("showDashboard")
    static let showCalendar = Notification.Name("showCalendar")
    static let wakeWordDetected = Notification.Name("wakeWordDetected")
    static let showVoiceAction = Notification.Name("showVoiceAction")
    static let toggleTheme = Notification.Name("toggleTheme")
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
    static let quickActionReceived = Notification.Name("quickActionReceived")
    static let showClipboardHistory = Notification.Name("showClipboardHistory")
}
