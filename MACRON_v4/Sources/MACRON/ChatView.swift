import SwiftUI
import AVFoundation

struct ChatView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var textInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var ttsEnabled = true
    @State private var ttsSpeed: Double = 0.5
    @StateObject private var speechService = SpeechService()
    @StateObject private var ttsService = TTSService()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Chat MACRON").font(.title2.bold())
                Spacer()
                HStack(spacing: 8) {
                    Toggle("TTS", isOn: $ttsEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    if ttsEnabled {
                        Slider(value: $ttsSpeed, in: 0.3...0.8, step: 0.1)
                            .frame(width: 80)
                            .onChange(of: ttsSpeed) { ttsService.rate = Float($1) }
                    }
                    Button(action: loadMemory) {
                        Image(systemName: "clock.arrow.circlepath")
                    }.buttonStyle(.plain).help("Cargar memoria")
                    Button(action: clearMemory) {
                        Image(systemName: "trash").foregroundColor(.red)
                    }.buttonStyle(.plain).help("Borrar memoria")
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
                                Text("MACRON recuerda las ultimas 20 interacciones").font(.caption2).foregroundColor(.secondary.opacity(0.7))
                            }.frame(maxWidth: .infinity, minHeight: 200).padding()
                        }
                        ForEach(messages) { msg in MessageBubble(message: msg, onSpeak: ttsEnabled ? { ttsService.speak(msg.text) } : nil).id(msg.id) }
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
                
                NativeTextField(text: $textInput, placeholder: "Escribe o dicta...", onSubmit: sendMessage)
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
        .onAppear { loadMemory() }
        .onChange(of: speechService.transcript) { _, newValue in
            if !newValue.isEmpty { textInput = newValue }
        }
        .onChange(of: speechService.isRecording) { _, isRecording in
            if !isRecording && !speechService.transcript.isEmpty { sendMessage() }
        }
    }
    
    private func toggleSpeech() {
        Task { await speechService.toggleRecording() }
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
                    if let text = response.text {
                        messages.append(ChatMessage(text: text, isUser: false))
                        if ttsEnabled { ttsService.speak(text) }
                    } else if let error = response.error {
                        messages.append(ChatMessage(text: "Error: \\(error)", isUser: false, isError: true))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    messages.append(ChatMessage(text: "Error: \\(error.localizedDescription)", isUser: false, isError: true))
                }
            }
        }
    }
    
    private func loadMemory() {
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/memory")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let mem = json?["memory"] as? [[String: Any]] {
                    var newMessages: [ChatMessage] = []
                    for m in mem {
                        let role = m["role"] as? String ?? ""
                        let text = m["text"] as? String ?? ""
                        newMessages.append(ChatMessage(text: text, isUser: role == "user"))
                    }
                    await MainActor.run { self.messages = newMessages }
                }
            } catch { print("Error cargando memoria: \\(error)") }
        }
    }
    
    private func clearMemory() {
        Task {
            do {
                let url = URL(string: "http://localhost:5001/api/memory/clear")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                let _ = try await URLSession.shared.data(for: request)
                await MainActor.run { self.messages = [] }
            } catch { print("Error borrando memoria: \\(error)") }
        }
    }
}

class TTSService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    var rate: Float = 0.5
    
    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
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
    var onSpeak: (() -> Void)? = nil
    
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
                HStack(spacing: 4) {
                    Text(message.text)
                        .padding(12)
                        .background(backgroundColor)
                        .foregroundColor(foregroundColor)
                        .cornerRadius(16)
                        .frame(maxWidth: 500, alignment: message.isUser ? .trailing : .leading)
                    if let speak = onSpeak, !message.isUser {
                        Button(action: speak) {
                            Image(systemName: "speaker.wave.2.fill").font(.caption2)
                        }.buttonStyle(.plain).foregroundColor(.secondary)
                    }
                }
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var isAnimating = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle().fill(Color.secondary).frame(width: 6, height: 6)
                    .offset(y: isAnimating ? -4 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.15), value: isAnimating)
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(16)
        .onAppear { isAnimating = true }
    }
}
