import SwiftUI

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
