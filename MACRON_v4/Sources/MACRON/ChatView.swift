import SwiftUI

struct ChatView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var textInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @StateObject private var speechService = SpeechService()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Chat MLX").font(.title2.bold())
                Spacer()
                if let model = api.status?.hardware?.model {
                    Label(model, systemImage: "cpu").font(.caption).foregroundColor(.secondary)
                }
            }.padding(.horizontal).padding(.top, 8)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.5))
                                Text("Inicia una conversacion con MACRON").font(.caption).foregroundColor(.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 200).padding()
                        }
                        ForEach(messages) { msg in MessageBubble(message: msg).id(msg.id) }
                        if isLoading { HStack { Spacer(); TypingIndicator(); Spacer() }.padding(.horizontal) }
                    }.padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: toggleSpeech) {
                    Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                        .font(.title3)
                        .foregroundColor(speechService.isRecording ? .red : .primary)
                }.buttonStyle(.plain)
                
                NativeTextField(text: $textInput, placeholder: "Escribe un mensaje...", onSubmit: sendMessage)
                    .frame(height: 32)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(textInput.isEmpty ? .gray : .accentColor)
                }.buttonStyle(.plain).disabled(textInput.isEmpty || isLoading)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
        .background(Color(.windowBackgroundColor))
        .onChange(of: speechService.transcript) { _, newValue in
            if !newValue.isEmpty {
                textInput = newValue
            }
        }
        .onChange(of: speechService.isRecording) { _, isRecording in
            if !isRecording && !speechService.transcript.isEmpty {
                sendMessage()
            }
        }
    }
    
    private func toggleSpeech() {
        Task {
            await speechService.toggleRecording()
        }
    }
    
    private func sendMessage() {
        guard !textInput.isEmpty, !isLoading else { return }
        let userText = textInput
        messages.append(ChatMessage(text: userText, isUser: true))
        textInput = ""
        isLoading = true
        
        Task {
            do {
                let response = try await api.sendChat(message: userText)
                await MainActor.run {
                    isLoading = false
                    if let text = response.response {
                        messages.append(ChatMessage(text: text, isUser: false))
                    } else if let error = response.error {
                        messages.append(ChatMessage(text: "Error: \(error)", isUser: false, isError: true))
                    } else {
                        messages.append(ChatMessage(text: "Error: Respuesta vacia", isUser: false, isError: true))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false, isError: true))
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let isError: Bool
    let timestamp: Date
    
    init(text: String, isUser: Bool, isError: Bool = false) {
        self.text = text
        self.isUser = isUser
        self.isError = isError
        self.timestamp = Date()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var backgroundColor: Color {
        if message.isError { return .red.opacity(0.2) }
        return message.isUser ? Color.accentColor : Color(.controlBackgroundColor)
    }
    
    var foregroundColor: Color {
        if message.isError { return .red }
        return message.isUser ? .white : .primary
    }
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(backgroundColor)
                    .foregroundColor(foregroundColor)
                    .cornerRadius(16)
                    .frame(maxWidth: 500, alignment: message.isUser ? .trailing : .leading)
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var offset: CGFloat = 0
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .offset(y: isAnimating ? -4 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: isAnimating)
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(16)
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
    }
}
