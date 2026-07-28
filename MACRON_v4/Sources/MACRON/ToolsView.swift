import SwiftUI

struct ToolsView: View {
    @State private var toolOutput = ""
    @State private var selectedTool = 0
    
    let toolNames = ["Contexto", "Spotlight", "Shell", "Recordatorio", "Nota", "Biometricos", "Proactive Log"]
    let toolIcons = ["eye.fill", "magnifyingglass", "terminal", "bell.fill", "note.text", "lock.shield.fill", "bolt.fill"]
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Herramienta", selection: $selectedTool) {
                ForEach(0..<toolNames.count, id: \.self) { index in
                    Text(toolNames[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Button("Ejecutar Tool") {
                toolOutput = executeTool(index: selectedTool)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            ScrollView {
                Text(toolOutput.isEmpty ? "Selecciona una herramienta y presiona Ejecutar" : toolOutput)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.textBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
    }
    
    private func executeTool(index: Int) -> String {
        switch index {
        case 0: return VoiceContextEngine.shared.currentContext.enrichedPrompt
        case 1: return AgentOrchestrator.shared.execute(toolName: "search_spotlight", arguments: ["query": "MACRON"])
        case 2: return AgentOrchestrator.shared.execute(toolName: "run_shell", arguments: ["command": "pwd"])
        case 3: return AgentOrchestrator.shared.execute(toolName: "set_reminder", arguments: ["title": "Test", "body": "Desde MACRON UI", "seconds": "60"])
        case 4: return AgentOrchestrator.shared.execute(toolName: "write_note", arguments: ["title": "UI Test", "content": "Creado desde la interfaz nativa de MACRON"])
        case 5: return VoiceBiometrics.shared.isTrained ? "Voiceprint: Entrenado" : "Voiceprint: No entrenado"
        case 6: return ProactiveAI.shared.log().joined(separator: "\n")
        default: return "Tool no implementada"
        }
    }
}
