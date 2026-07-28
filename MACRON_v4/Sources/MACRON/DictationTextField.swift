import SwiftUI
import Speech

struct DictationTextField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isDictating = false
    @StateObject private var speechService = SpeechService()
    
    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
            
            Button(action: {
                Task {
                    if isDictating {
                        speechService.stopRecording()
                        isDictating = false
                    } else {
                        let success = await speechService.startRecording()
                        if success {
                            isDictating = true
                        }
                    }
                }
            }) {
                Image(systemName: isDictating ? "mic.fill" : "mic")
                    .foregroundColor(isDictating ? .red : .orange)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .onChange(of: speechService.transcript) { _, newValue in
            if isDictating && !newValue.isEmpty {
                text = newValue
            }
        }
        .onDisappear {
            if isDictating {
                speechService.stopRecording()
            }
        }
    }
}
