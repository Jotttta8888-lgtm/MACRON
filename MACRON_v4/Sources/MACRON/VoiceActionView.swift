import SwiftUI
import AVFoundation

struct VoiceActionView: View {
    @ObservedObject var api: MacronAPIClient
    @StateObject private var voiceService: VoiceActionService
    @Environment(\.dismiss) private var dismiss
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    
    init(api: MacronAPIClient) {
        self.api = api
        self._voiceService = StateObject(wrappedValue: VoiceActionService(apiClient: api))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // ONDAS ANIMADAS cuando escucha
                VoiceWaveView(isActive: .constant(voiceService.isListening))
                    .frame(height: 120)
                    .padding(.top, 10)
                
                micStatusText
                modeToggle
                transcriptView
                resultsList
                errorView
                Spacer()
                actionButton
            }
            .padding()
            .frame(minWidth: 450, minHeight: 550)
            .navigationTitle("Voice Action")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private var micStatusText: some View {
        Text(voiceService.micStatus)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private var modeToggle: some View {
        HStack(spacing: 12) {
            Text("Modo continuo")
                .font(.subheadline)
            Toggle("", isOn: Binding(
                get: { voiceService.isContinuousMode },
                set: { _ in voiceService.toggleContinuousMode() }
            ))
            .toggleStyle(.switch)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var transcriptView: some View {
        if !voiceService.transcript.isEmpty {
            Text(voiceService.transcript)
                .font(.body)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(10)
        }
    }
    
    @ViewBuilder
    private var resultsList: some View {
        if !voiceService.actionResults.isEmpty {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(voiceService.actionResults.enumerated()), id: \.offset) { index, result in
                        ResultCard(result: result, index: index)
                            .onAppear {
                                speak(result.response ?? "Listo")
                                if index == voiceService.actionResults.count - 1 {
                                    navigateIfNeeded(result)
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 280)
        }
    }
    
    @ViewBuilder
    private var errorView: some View {
        if let errorMsg = voiceService.errorMessage, !errorMsg.isEmpty {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(errorMsg)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var actionButton: some View {
        Button(action: {
            Task {
                if voiceService.isContinuousMode || voiceService.isListening {
                    voiceService.stopVoiceAction()
                } else {
                    await voiceService.startVoiceAction()
                }
            }
        }) {
            HStack {
                Image(systemName: buttonIcon)
                Text(buttonText)
            }
            .font(.title3)
            .foregroundColor(.white)
            .padding(.horizontal, 35)
            .padding(.vertical, 12)
            .background(buttonColor)
            .cornerRadius(25)
        }
        .buttonStyle(.plain)
        .disabled(!voiceService.isMicHealthy && !voiceService.isListening)
    }
    
    private var buttonIcon: String {
        if voiceService.isContinuousMode || voiceService.isListening { return "stop.fill" }
        return "mic.fill"
    }
    
    private var buttonText: String {
        if voiceService.isContinuousMode { return "Detener continuo" }
        if voiceService.isListening { return "Detener" }
        return "Hablar"
    }
    
    private var buttonColor: Color {
        if voiceService.isContinuousMode || voiceService.isListening { return .red }
        if !voiceService.isMicHealthy { return .gray }
        return .orange
    }
    
    private func navigateIfNeeded(_ result: VoiceActionResponse) {
        let action = result.action ?? ""
        var tabIndex: Int? = nil
        if action.hasPrefix("focus_") { tabIndex = 8 }
        else if action.hasPrefix("safari_") { tabIndex = 6 }
        else if action.hasPrefix("mail_") { tabIndex = 7 }
        else if action.hasPrefix("calendar_") { tabIndex = 2 }
        else if action == "chat" { tabIndex = 1 }
        
        if let index = tabIndex, !voiceService.isContinuousMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(
                    name: .voiceActionNavigate,
                    object: nil,
                    userInfo: ["tabIndex": index]
                )
                dismiss()
            }
        }
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
}

struct ResultCard: View {
    @StateObject private var favorites = FavoritesService()
    let result: VoiceActionResponse
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(index + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(result.method ?? "")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Text("Accion: \(result.action ?? "desconocida")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text(result.response ?? "Sin respuesta")
                .font(.body)
            
            if let output = result.result?["output"], !output.isEmpty {
                Text("→ \(output)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
            
            if let error = result.result?["error"], !error.isEmpty {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            HStack {
                Spacer()
                Button(action: {
                    let text = result.original_text ?? result.response ?? ""
                    if favorites.favorites.contains(text) {
                        favorites.remove(text)
                    } else {
                        favorites.add(text)
                    }
                }) {
                    Image(systemName: favorites.favorites.contains(result.original_text ?? result.response ?? "") ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}
