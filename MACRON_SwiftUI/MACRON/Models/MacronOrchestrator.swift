import Foundation
import Combine

class MacronOrchestrator: ObservableObject {
    @Published var isOnline = false
    @Published var hardware = HardwareInfo()
    @Published var modules = ModuleStatus()
    
    private let pythonPath: String
    private let scriptPath: String
    
    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.pythonPath = "\(home)/Documents/MACRON/venv/bin/python3"
        self.scriptPath = "\(home)/Documents/MACRON/MACRON_FUNCIONALIDADES_v2.py"
        refreshStatus()
    }
    
    func refreshStatus() {
        runPython("from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); print(json.dumps(m.status()))") { output in
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
        let script = "from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator(); r = m.llm.chat('\(escaped)'); print(r.get('text', r.get('error', 'Error')))"
        runPython(script) { output in
            completion(output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Error
cd ~/Documents/MACRON/MACRON_SwiftUI

# ContentView.swift
cat > MACRON/Views/ContentView.swift << 'SWIFT'
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
                    Button("Scan") { orchestrator.scanIntrusions() }
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
