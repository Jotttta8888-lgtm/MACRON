import SwiftUI
import AppKit
import Combine

struct ContentView: View {
    @ObservedObject var api = MacronAPIClient.shared
    @StateObject var wakeService = WakeWordService()
    @StateObject var focusDetector = FocusDetector()
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showVoiceAction = false
    @State private var voiceActionCancellable: AnyCancellable?
    @State private var navigateCancellable: AnyCancellable?
    @State private var settingsCancellable: AnyCancellable?
    @State private var wakeCancellable: AnyCancellable?
    
    let tabs = [
        ("Dashboard", "gauge.with.dots.needle.67percent"),
        ("Chat", "bubble.left.and.bubble.right"),
        ("Calendario", "calendar"),
        ("Notas", "note.text"),
        ("Recordatorios", "bell.badge"),
        ("Finder", "magnifyingglass"),
        ("Safari", "safari"),
        ("Mail", "envelope"),
        ("Focus", "moon.fill"),
        ("Research", "globe"),
        ("Analytics", "chart.bar"),
        ("Comandos", "command"),
    ]
    
    var body: some View {
        NavigationSplitView {
            
            Sidebar(tabs: tabs, selectedTab: $selectedTab)
                .frame(minWidth: 220)
        } detail: {
            NavigationStack {
                DetailView(selectedTab: selectedTab).animation(.easeInOut(duration: 0.3), value: selectedTab)
                        .transition(.slide)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(api)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    if focusDetector.isInMeeting {
                        HStack {
                            Image(systemName: "phone.fill").foregroundColor(.red).font(.caption2)
                            Text("En reunión").font(.caption).foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                    StatusBar()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { NotificationCenter.default.post(name: .toggleTheme, object: nil) }) {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundColor(.yellow)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    if wakeService.isListening {
                        Image(systemName: "ear.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .help("Wake word activo: di 'Hey MACRON'")
                    }
                    Button(action: { showVoiceAction = true }) {
                        Image(systemName: "mic.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showSettings = true }) { Image(systemName: "gear") }
            }
        }
        .sheet(isPresented: $showVoiceAction) { VoiceActionView(api: api) }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onAppear { setupNotifications() }
        .onDisappear { cleanupNotifications() }
    }
    
    private func setupNotifications() {
        settingsCancellable = NotificationCenter.default.publisher(for: .showSettings)
            .sink { _ in showSettings = true }
        
        navigateCancellable = NotificationCenter.default.publisher(for: .voiceActionNavigate)
            .sink { notification in
                if let userInfo = notification.userInfo,
                   let tabIndex = userInfo["tabIndex"] as? Int {
                    selectedTab = tabIndex
                    showVoiceAction = false
                }
            }
        
        voiceActionCancellable = NotificationCenter.default.publisher(for: .showVoiceAction)
            .sink { _ in
                    // Foco automatico DESACTIVADO\n                    // Foco automatico DESACTIVADO\n                    }
                    showVoiceAction = true
                }
        
        wakeCancellable = NotificationCenter.default.publisher(for: .wakeWordDetected)
            .sink { _ in
                print("[ContentView] Wake word detectado - abriendo Voice Action")
                showVoiceAction = true
            }
    }
    
    private func cleanupNotifications() {
        settingsCancellable?.cancel()
        settingsCancellable = nil
        navigateCancellable?.cancel()
        navigateCancellable = nil
        voiceActionCancellable?.cancel()
        voiceActionCancellable = nil
        wakeCancellable?.cancel()
        wakeCancellable = nil
    }
}

struct Sidebar: View {
    let tabs: [(String, String)]
    @Binding var selectedTab: Int
    
    var body: some View {
        List(0..<tabs.count, id: \.self, selection: $selectedTab) { index in
            Label(tabs[index].0, systemImage: tabs[index].1).tag(index)
        }
    }
}

struct StatusBar: View {
    @StateObject var api = MacronAPIClient.shared
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(api.isOnline ? Color.green : Color.red).frame(width: 8, height: 8)
            Text(api.isOnline ? "Online" : "Offline").font(.caption).foregroundColor(.secondary)
        }
    }
}
