import SwiftUI

struct ContentView: View {
    @StateObject private var orchestrator = MacronOrchestrator()
    @State private var selectedTab = 0

    let tabs = ["Dashboard", "Chat", "Vault", "Planes", "FaceRec"]
    let tabIcons = ["cpu", "message", "lock.shield", "list.bullet.rectangle", "faceid"]

    var body: some View {
        NavigationSplitView {
            List(0..<tabs.count, id: \.self, selection: $selectedTab) { index in
                Label(tabs[index], systemImage: tabIcons[index])
                    .tag(index)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            Group {
                switch selectedTab {
                case 0: DashboardView(orchestrator: orchestrator)
                case 1: ChatView(orchestrator: orchestrator)
                case 2: VaultView(orchestrator: orchestrator)
                case 3: PlansView(orchestrator: orchestrator)
                case 4: FaceRecView(orchestrator: orchestrator)
                default: DashboardView(orchestrator: orchestrator)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .foregroundColor(orchestrator.isOnline ? .green : .red)
                        .font(.system(size: 8))
                    Text("MACRON v2.1")
                        .font(.headline)
                }
            }
        }
    }
}

struct DashboardView: View {
    @ObservedObject var orchestrator: MacronOrchestrator

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                    StatCard(title: "Apple Silicon", value: orchestrator.hardware.appleSilicon ? "M1/M2" : "Intel", icon: "cpu", color: .cyan)
                    StatCard(title: "MLX", value: orchestrator.hardware.mlx ? "Activo" : "Inactivo", icon: "bolt.fill", color: .green)
                    StatCard(title: "RAM", value: "\(orchestrator.hardware.ramGB) GB", icon: "memorychip", color: .orange)
                    StatCard(title: "Modelo", value: orchestrator.hardware.modelSize, icon: "brain", color: .purple)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Modulos")
                        .font(.title2.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                        ModuleBadge(name: "RAG", active: orchestrator.modules.rag)
                        ModuleBadge(name: "Planning", active: orchestrator.modules.planning)
                        ModuleBadge(name: "CoT", active: orchestrator.modules.cot)
                        ModuleBadge(name: "Rutinas", active: orchestrator.modules.rutinas)
                        ModuleBadge(name: "FaceRec", active: orchestrator.modules.faceRec)
                        ModuleBadge(name: "Vault", active: orchestrator.modules.vault)
                        ModuleBadge(name: "Trans", active: orchestrator.modules.transcription)
                        ModuleBadge(name: "Code", active: orchestrator.modules.codeCompletion)
                        ModuleBadge(name: "LLM", active: orchestrator.modules.llm)
                        ModuleBadge(name: "Intrusion", active: orchestrator.modules.intrusion)
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .cornerRadius(12)

                HStack(spacing: 12) {
                    Button("Voz") { orchestrator.activateVoice() }
                    Button("Screenshot") { orchestrator.takeScreenshot() }
                }
            }
            .padding()
        }
    }
}

struct StatCard: View {
    let title: String, value: String, icon: String, color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Image(systemName: icon).foregroundColor(color); Spacer() }
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .padding().frame(height: 100)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ModuleBadge: View {
    let name: String, active: Bool
    var body: some View {
        HStack {
            Circle().fill(active ? Color.green : Color.gray).frame(width: 8, height: 8)
            Text(name).font(.caption)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(active ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ChatView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var textInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isListening = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.isUser { Spacer() }
                            Text(msg.text)
                                .padding(12)
                                .background(msg.isUser ? Color.accentColor : Color(.controlBackgroundColor))
                                .foregroundColor(msg.isUser ? .white : .primary)
                                .cornerRadius(16)
                                .frame(maxWidth: 300, alignment: msg.isUser ? .trailing : .leading)
                            if !msg.isUser { Spacer() }
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: toggleVoice) {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .font(.title2)
                        .foregroundColor(isListening ? .red : .accentColor)
                }
                .buttonStyle(.plain)

                TextField("Escribe...", text: $textInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendMessage() }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(textInput.isEmpty)
            }
            .padding()
        }
    }

    private func sendMessage() {
        guard !textInput.isEmpty else { return }
        messages.append(ChatMessage(text: textInput, isUser: true))
        orchestrator.sendChat(textInput) { response in
            DispatchQueue.main.async {
                messages.append(ChatMessage(text: response, isUser: false))
            }
        }
        textInput = ""
    }

    private func toggleVoice() {
        isListening.toggle()
        if isListening {
            orchestrator.processVoiceCommand { result in
                DispatchQueue.main.async {
                    isListening = false
                    messages.append(ChatMessage(text: result.input, isUser: true))
                    messages.append(ChatMessage(text: result.response, isUser: false))
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct VaultView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var password = "", key = "", value = "", result = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Vault").font(.title2.bold())
            SecureField("Password", text: $password).textFieldStyle(.roundedBorder)
            TextField("Key", text: $key).textFieldStyle(.roundedBorder)
            SecureField("Value", text: $value).textFieldStyle(.roundedBorder)
            HStack {
                Button("Guardar") { result = "Guardado" }
                Button("Recuperar") { result = "Recuperado" }
            }
            if !result.isEmpty { Text(result).padding().background(Color(.textBackgroundColor)).cornerRadius(8) }
            Spacer()
        }.padding().frame(maxWidth: 500)
    }
}

struct PlansView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var title = "", description = "", steps = ""
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nuevo Plan").font(.title3.bold())
                TextField("Titulo", text: $title).textFieldStyle(.roundedBorder)
                TextField("Descripcion", text: $description).textFieldStyle(.roundedBorder)
                TextField("Pasos (sep. por coma)", text: $steps).textFieldStyle(.roundedBorder)
                Button("Crear") { }.buttonStyle(.borderedProminent)
                Spacer()
            }.frame(width: 300).padding()
            Divider()
            VStack(alignment: .leading) {
                Text("Planes").font(.title3.bold())
                Spacer()
            }.padding()
        }
    }
}

struct FaceRecView: View {
    @ObservedObject var orchestrator: MacronOrchestrator
    @State private var name = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Face Recognition").font(.title2.bold())
            Image(systemName: "faceid").font(.system(size: 60)).foregroundColor(.accentColor)
            Text(orchestrator.modules.faceRec ? "dlib activo" : "dlib no instalado")
                .foregroundColor(orchestrator.modules.faceRec ? .green : .red)
            TextField("Nombre", text: $name).textFieldStyle(.roundedBorder).frame(maxWidth: 300)
            Button("Registrar") { }.buttonStyle(.borderedProminent)
            Spacer()
        }.padding()
    }
}

struct MenuBarView: View {
    @StateObject private var orchestrator = MacronOrchestrator()
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "cpu").foregroundColor(.accentColor)
                Text("MACRON").font(.headline)
                Spacer()
                Circle().fill(orchestrator.isOnline ? Color.green : Color.red).frame(width: 8, height: 8)
            }
            Divider()
            VStack(spacing: 8) {
                HStack { Image(systemName: "brain").foregroundColor(.green); Text("LLM"); Spacer(); Circle().fill(orchestrator.modules.llm ? Color.green : Color.gray).frame(width: 6, height: 6) }
                HStack { Image(systemName: "mic").foregroundColor(.green); Text("Voz"); Spacer(); Circle().fill(orchestrator.modules.transcription ? Color.green : Color.gray).frame(width: 6, height: 6) }
                HStack { Image(systemName: "lock").foregroundColor(.green); Text("Vault"); Spacer(); Circle().fill(orchestrator.modules.vault ? Color.green : Color.gray).frame(width: 6, height: 6) }
            }
            Divider()
            Button("Abrir Dashboard") { NSApp.activate(ignoringOtherApps: true) }.buttonStyle(.borderedProminent)
            Button("Activar Voz") { orchestrator.activateVoice() }.buttonStyle(.bordered)
            Button("Salir") { NSApp.terminate(nil) }.buttonStyle(.plain).foregroundColor(.red)
        }.padding().frame(width: 220)
    }
}

class MacronOrchestrator: ObservableObject {
    @Published var isOnline = false
    @Published var hardware = HardwareInfo()
    @Published var modules = ModuleStatus()

    private let pythonPath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.pythonPath = home + "/Documents/MACRON/venv/bin/python3"
        refreshStatus()
    }

    func refreshStatus() {
        runPython("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); print(__import__('json').dumps(m.status()))") { output in
            guard let data = output?.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                self.isOnline = false
                return
            }
            DispatchQueue.main.async {
                self.isOnline = true
                if let hw = json["hardware"] as? [String: Any] {
                    self.hardware = HardwareInfo(
                        appleSilicon: hw["apple_silicon"] as? Bool ?? false,
                        mlx: hw["mlx"] as? Bool ?? false,
                        mps: hw["mps"] as? Bool ?? false,
                        ramGB: hw["ram_gb"] as? Double ?? 0,
                        modelSize: hw["model_size"] as? String ?? ""
                    )
                }
                if let mod = json["modules"] as? [String: Bool] {
                    self.modules = ModuleStatus(
                        rag: mod["rag"] ?? false,
                        planning: mod["planning"] ?? false,
                        cot: mod["cot"] ?? false,
                        rutinas: mod["rutinas"] ?? false,
                        faceRec: mod["face_rec"] ?? false,
                        notion: mod["notion"] ?? false,
                        multiDevice: mod["multi_device"] ?? false,
                        intrusion: mod["intrusion"] ?? false,
                        vault: mod["vault"] ?? false,
                        transcription: mod["transcription"] ?? false,
                        codeCompletion: mod["code_completion"] ?? false,
                        llm: mod["llm"] ?? false
                    )
                }
            }
        }
    }

    func activateVoice() {
        runPython("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); m.control.speak('Hola, dime algo')") { _ in }
    }

    func processVoiceCommand(completion: @escaping (VoiceResult) -> Void) {
        let script = """
import json, os
from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator
m = MacronOrchestrator()
result = m.process_voice_command()
print(json.dumps(result))
"""
        runPython(script) { output in
            guard let data = output?.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(VoiceResult(success: false, input: "", response: "Error"))
                return
            }
            completion(VoiceResult(
                success: json["success"] as? Bool ?? false,
                input: json["input"] as? String ?? "",
                response: json["response"] as? String ?? ""
            ))
        }
    }

    func sendChat(_ message: String, completion: @escaping (String) -> Void) {
        let escaped = message.replacingOccurrences(of: "'", with: "\\'")
        let script = "from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); r = m.llm.chat('" + escaped + "'); print(r.get('text', r.get('error', 'Error')))"
        runPython(script) { output in
            completion(output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Error")
        }
    }

    func takeScreenshot() {
        runPython("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); m.control.screenshot()") { _ in }
    }

    private func runPython(_ script: String, completion: @escaping (String?) -> Void) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: pythonPath)
        task.arguments = ["-c", script]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            completion(String(data: data, encoding: .utf8))
        } catch {
            completion(nil)
        }
    }
}

struct HardwareInfo {
    var appleSilicon = false
    var mlx = false
    var mps = false
    var ramGB: Double = 0
    var modelSize = ""
}

struct ModuleStatus {
    var rag = false
    var planning = false
    var cot = false
    var rutinas = false
    var faceRec = false
    var notion = false
    var multiDevice = false
    var intrusion = false
    var vault = false
    var transcription = false
    var codeCompletion = false
    var llm = false
}

struct VoiceResult {
    let success: Bool
    let input: String
    let response: String
}
