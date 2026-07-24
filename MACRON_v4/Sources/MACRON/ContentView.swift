import SwiftUI

struct ContentView: View {
    @ObservedObject var api = MacronAPIClient.shared
    @State private var selectedTab = 0
    @State private var showSettings = false
    
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
    ]
    
    var body: some View {
        NavigationSplitView {
            Sidebar(tabs: tabs, selectedTab: $selectedTab)
                .frame(minWidth: 220)
        } detail: {
            NavigationStack {
                DetailView(selectedTab: selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(api)
        .toolbar {
            ToolbarItem(placement: .principal) { StatusBar() }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showSettings = true }) { Image(systemName: "gear") }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in showSettings = true }
    }
}

struct Sidebar: View {
    let tabs: [(String, String)]
    @Binding var selectedTab: Int
    
    var body: some View {
        List(0..<tabs.count, id: \.self, selection: $selectedTab) { index in
            Label(tabs[index].0, systemImage: tabs[index].1).tag(index)
        }
        .listStyle(.sidebar)
        .navigationTitle("MACRON")
    }
}

struct DetailView: View {
    let selectedTab: Int
    @EnvironmentObject var api: MacronAPIClient
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0: DashboardView()
            case 1: ChatView()
            case 2: CalendarView()
            case 3: NotesView()
            case 4: RemindersView()
            case 5: FinderView()
            case 6: SafariView()
            case 7: MailView()
            case 8: FocusView()
            case 9: ResearchView()
            case 10: AnalyticsView()
            default: DashboardView()
            }
        }
    }
}

struct StatusBar: View {
    @EnvironmentObject var api: MacronAPIClient
    
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(api.isOnline ? Color.green : Color.red).frame(width: 8, height: 8)
            Text("MACRON v\(api.status?.version ?? "--")").font(.headline)
            if let model = api.status?.hardware?.model {
                Text("| \(model)").font(.caption).foregroundColor(.secondary)
            }
            if let uptime = api.status?.uptimeFormatted {
                Text("| Uptime: \(uptime)").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
