import SwiftUI
struct ChatView: View {
    @ObservedObject var brainState: BrainState
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isProcessing = false
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in MessageBubble(message: msg) }
                        if isProcessing {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("MACRON esta pensando...").font(.caption).foregroundColor(.secondary)
                                Spacer()
                            }.padding(.horizontal)
                        }
                    }.padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            Divider()
            HStack(spacing: 12) {
                TextField("Escribe o di 'Hey Macron'...", text: $messageText)
                    .textFieldStyle(.roundedBorder).focused($isFocused).onSubmit { sendMessage() }
                Button { sendMessage() } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }
                    .disabled(messageText.isEmpty || isProcessing)
                    .keyboardShortcut(.return, modifiers: .command)
            }.padding()
        }.background(Color(.windowBackgroundColor))
    }
    private func sendMessage() {
        guard !messageText.isEmpty, !isProcessing else { return }
        let text = messageText; messageText = ""; isProcessing = true
        messages.append(ChatMessage(id: UUID(), text: text, isUser: true, timestamp: Date()))
        Task {
            let response = await MACRONBrain.shared.processUserMessage(text, source: .text)
            DispatchQueue.main.async {
                messages.append(ChatMessage(id: UUID(), text: response, isUser: false, timestamp: Date()))
                isProcessing = false
            }
        }
    }
}
struct ChatMessage: Identifiable {
    let id: UUID, text: String, isUser: Bool, timestamp: Date
}
struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack {
            if !message.isUser { Spacer(minLength: 60) }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text).padding(12)
                    .background(message.isUser ? Color.accentColor : Color(.controlBackgroundColor))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16).textSelection(.enabled)
                Text(message.timestamp, style: .time).font(.caption2).foregroundColor(.secondary)
            }
            if message.isUser { Spacer(minLength: 60) }
        }
    }
}
