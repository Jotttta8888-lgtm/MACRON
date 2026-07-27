import SwiftUI

struct GlobalSearchView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @EnvironmentObject var api: MacronAPIClient
    
    let commands = [
        "Abrir Safari", "Abrir Mail", "Abrir Finder", "Abrir Terminal",
        "Abrir VS Code", "Abrir WhatsApp", "Abrir Zoom", "Abrir Notion",
        "Crear nota", "Crear recordatorio", "Ver calendario", "Modo focus",
        "Activar voz", "Ver historial", "Exportar datos", "Ver analytics"
    ]
    
    var filtered: [String] {
        if searchText.isEmpty { return commands }
        return commands.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Buscar comandos, apps, historial...", text: $searchText)
                    .font(.body)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            List(filtered, id: \.self) { cmd in
                Button(action: {
                    Task {
                        do {
                            let url = URL(string: "http://localhost:5001/api/voice-action")!
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            let body = ["text": cmd]
                            request.httpBody = try JSONSerialization.data(withJSONObject: body)
                            let _ = try await URLSession.shared.data(for: request)
                        } catch {}
                    }
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "command").foregroundColor(.accentColor)
                        Text(cmd)
                        Spacer()
                        Image(systemName: "arrow.right").font(.caption).foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .frame(width: 500, height: 400)
    }
}
