import SwiftUI

struct ContentView: View {
    @StateObject private var brainState = BrainState()
    @State private var selectedTab = 0
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab, brainState: brainState)
                .frame(minWidth: 220)
        } detail: {
            Group {
                switch selectedTab {
                case 0: DashboardView(brainState: brainState)
                case 1: ChatView(brainState: brainState)
                case 2: FeatureGridView()
                case 3: ToolsView()
                case 4: MACRONSettingsView(brainState: brainState)
                default: DashboardView(brainState: brainState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: brainState.isRunning ? "brain.head.profile.fill" : "brain.head.profile")
                        .foregroundColor(brainState.isRunning ? .green : .gray)
                        .symbolEffect(.pulse, isActive: brainState.isRunning)
                    Text("MACRON").font(.headline)
                    if brainState.isRunning {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
}

class BrainState: ObservableObject {
    @Published var isRunning = false
    @Published var lastMessage = ""
    @Published var lastTranscript = ""
    @Published var lastResponse = ""
    @Published var contextApp = ""
    @Published var proactiveInsights: [String] = []
    init() {
        MACRONBrain.shared.onSystemMessage = { [weak self] msg in
            DispatchQueue.main.async { self?.lastMessage = msg }
        }
        MACRONBrain.shared.onUserTranscript = { [weak self] text in
            DispatchQueue.main.async { self?.lastTranscript = text }
        }
        MACRONBrain.shared.onAIResponse = { [weak self] response in
            DispatchQueue.main.async { self?.lastResponse = response }
        }
    }
    func boot() { MACRONBrain.shared.boot(); isRunning = true }
    func shutdown() { MACRONBrain.shared.shutdown(); isRunning = false }
}
