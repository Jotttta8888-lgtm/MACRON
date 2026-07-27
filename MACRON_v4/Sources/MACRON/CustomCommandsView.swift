import SwiftUI
import AppKit

struct CustomCommand: Identifiable, Codable {
    let id: String
    let name: String
    let keywords: [String]
    let applescript: String
    let response: String
}

struct CustomCommandsView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var commands: [CustomCommand] = []
    @State private var showAddSheet = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Comandos Personalizados").font(.title2.bold())
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Label("Nuevo", systemImage: "plus")
                }
                Button(action: loadCommands) {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.plain)
            }.padding()
            
            if isLoading {
                ProgressView().padding()
            } else if commands.isEmpty {
                EmptyStateView(icon: "command", title: "Sin comandos", subtitle: "Crea tu primer comando personalizado")
            } else {
                List {
                    ForEach(commands) { cmd in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(cmd.name).font(.headline)
                                Spacer()
                                Button(action: { deleteCommand(cmd) }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }.buttonStyle(.plain)
                            }
                            Text("Keywords: " + cmd.keywords.joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                            Text(cmd.applescript.prefix(50) + "...").font(.caption2).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear { loadCommands() }
        .sheet(isPresented: $showAddSheet) { AddCustomCommandSheet(onSave: loadCommands) }
    }
    
    func loadCommands() {
        isLoading = true
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/custom-commands")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let cmds = json?["commands"] as? [[String: Any]] {
                    let decoder = JSONDecoder()
                    let cmdData = try JSONSerialization.data(withJSONObject: cmds)
                    commands = try decoder.decode([CustomCommand].self, from: cmdData)
                }
            } catch { print("Error: \\(error)") }
            isLoading = false
        }
    }
    
    func deleteCommand(_ cmd: CustomCommand) {
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/custom-commands?id=\\(cmd.id)")!
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                let _ = try await URLSession.shared.data(for: request)
                loadCommands()
            } catch { print("Error: \\(error)") }
        }
    }
}

struct AddCustomCommandSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var keywords = ""
    @State private var applescript = ""
    @State private var response = "Listo"
    @State private var isSaving = false
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Nuevo Comando").font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre").font(.headline)
                NativeTextField(text: $name, placeholder: "Ej: Abrir Terminal", onSubmit: nil)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Keywords (separadas por coma)").font(.headline)
                NativeTextField(text: $keywords, placeholder: "terminal, abrir terminal, consola", onSubmit: nil)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("AppleScript").font(.headline)
                TextEditor(text: $applescript).frame(minHeight: 80).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Respuesta de voz").font(.headline)
                NativeTextField(text: $response, placeholder: "Listo", onSubmit: nil)
            }
            
            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Button("Guardar") { save() }.disabled(name.isEmpty || applescript.isEmpty || isSaving)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 450)
    }
    
    func save() {
        isSaving = true
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/custom-commands")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: Any] = [
                    "name": name,
                    "keywords": keywords.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                    "applescript": applescript,
                    "response": response
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let _ = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    dismiss()
                    onSave()
                }
            } catch { print("Error: \\(error)"); isSaving = false }
        }
    }
}
