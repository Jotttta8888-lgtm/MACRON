import SwiftUI
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
