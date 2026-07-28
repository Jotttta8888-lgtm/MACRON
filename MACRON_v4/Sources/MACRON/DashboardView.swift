import SwiftUI

struct DashboardView: View {
    @ObservedObject var brainState: BrainState
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatusCard(brainState: brainState)
                ContextCard()
                QuickActionsGrid()
                ActivityLog(brainState: brainState)
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct StatusCard: View {
    @ObservedObject var brainState: BrainState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: brainState.isRunning ? "brain.head.profile.fill" : "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(brainState.isRunning ? .green : .secondary)
                VStack(alignment: .leading) {
                    Text(brainState.isRunning ? "MACRON Brain Activo" : "MACRON Brain Inactivo")
                        .font(.title2.bold())
                    Text(brainState.isRunning ? "Escuchando y procesando..." : "Presiona Activar Brain para comenzar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            if brainState.isRunning {
                HStack(spacing: 16) {
                    StatusBadge(icon: "mic.fill", text: "Voz", color: .blue)
                    StatusBadge(icon: "eye.fill", text: "Contexto", color: .purple)
                    StatusBadge(icon: "bolt.fill", text: "Proactivo", color: .orange)
                    StatusBadge(icon: "lock.shield.fill", text: "Biometrico", color: .green)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
    }
}

struct ContextCard: View {
    @State private var context = VoiceContextEngine.shared.currentContext
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eye")
                Text("Contexto Actual")
                    .font(.headline)
                Spacer()
                Text("Actualizado: \(Date(), style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(context.appName, systemImage: "app.fill")
                    Label(context.windowTitle, systemImage: "window.horizontal")
                    if let url = context.url { Label(url, systemImage: "link") }
                    if let file = context.filePath { Label(file, systemImage: "doc.fill") }
                }
                .font(.callout)
                Spacer()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.controlBackgroundColor)))
        .onReceive(timer) { _ in context = VoiceContextEngine.shared.currentContext }
    }
}

struct QuickActionsGrid: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
            QuickActionButton(title: "Modo Focus", icon: "target") {
                _ = WindowManagerAI.shared.focusMode()
            }
            QuickActionButton(title: "Leer Texto", icon: "speaker.wave.2.fill") {
                _ = ScreenReaderAI.shared.readSelectedText()
            }
            QuickActionButton(title: "Traducir", icon: "globe") {
                _ = QuickTranslate.shared.translateSelection()
            }
            QuickActionButton(title: "Nota Rapida", icon: "note.text") {
                _ = AgentOrchestrator.shared.execute(toolName: "write_note", arguments: ["title": "Rapida", "content": "Nota desde MACRON UI"])
            }
            QuickActionButton(title: "Ayuda Codigo", icon: "curlybraces") {
                _ = CodeAssistant.shared.contextualHelp()
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }
}

struct ActivityLog: View {
    @ObservedObject var brainState: BrainState
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actividad Reciente")
                .font(.headline)
            Divider()
            if !brainState.lastTranscript.isEmpty {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text(brainState.lastTranscript)
                        .lineLimit(2)
                    Spacer()
                }
            }
            if !brainState.lastResponse.isEmpty {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text(brainState.lastResponse)
                        .lineLimit(3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            if brainState.lastTranscript.isEmpty && brainState.lastResponse.isEmpty {
                Text("Sin actividad reciente")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.controlBackgroundColor)))
    }
}

struct StatusBadge: View {
    let icon: String
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}
