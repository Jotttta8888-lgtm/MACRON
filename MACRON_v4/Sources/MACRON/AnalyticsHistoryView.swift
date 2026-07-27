import SwiftUI
import AppKit

struct AnalyticsHistoryView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var history: [HistoryEntry] = []
    @State private var isLoading = false

    var body: some View {
        VStack {
            HStack {
                Text("Historial de Comandos").font(.title2).padding()
                Spacer()
                Button(action: exportHistory) {
                    Label("Exportar", systemImage: "square.and.arrow.up")
                }
                .padding()
            }
            
            if history.isEmpty {
                Text("No hay comandos registrados").foregroundColor(.secondary)
            } else {
                List(history.reversed()) { entry in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(entry.action ?? "chat").font(.caption).foregroundColor(.blue)
                            Spacer()
                            Text(entry.timestamp.prefix(10)).font(.caption2).foregroundColor(.secondary)
                        }
                        Text(entry.text).font(.body)
                    }
                }
            }
        }
        .onAppear { loadHistory() }
        .frame(minWidth: 400, minHeight: 400)
    }

    func loadHistory() {
        Task {
            do {
                let data = try await api.getVoiceHistory()
                history = data
            } catch { print("Error: \\(error)") }
        }
    }
    
    func exportHistory() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json, .plainText]
        savePanel.nameFieldStringValue = "macron_history_\\(Date().formatted(.iso8601)).json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(history)
                try data.write(to: url)
                print("✅ Exportado a \\(url.path)")
            } catch {
                print("❌ Error exportando: \\(error)")
            }
        }
    }
}

struct HistoryEntry: Identifiable, Codable {
    var id = UUID()
    let timestamp: String
    let text: String
    let action: String?
    let method: String?
}
