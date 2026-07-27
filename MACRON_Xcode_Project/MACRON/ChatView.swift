import SwiftUI

struct ChatView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var textInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Chat MLX").font(.title2.bold())
                Spacer()
                if let model = api.status?.hardware.model {
                    Label(model, systemImage: "cpu").font(.caption).foregroundColor(.secondary)
                }
            }.padding()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in MessageBubble(message: msg).id(msg.id) }
                        if isLoading { HStack { Spacer(); TypingIndicator(); Spacer() }.padding(.horizontal) }
                    }.padding()
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: {}) { Image(systemName: "mic").font(.title3) }.buttonStyle(.plain)
                TextField("Escribe un mensaje...", text: $textInput).textFieldStyle(.roundedBorder).onSubmit { sendMessage() }
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill").font(.title2).foregroundColor(textInput.isEmpty ? .gray : .accentColor)
                }.buttonStyle(.plain).disabled(textInput.isEmpty || isLoading)
            }.padding()
        }.background(Color(.windowBackgroundColor))
    }
    
    private func sendMessage() {
        guard !textInput.isEmpty, !isLoading else { return }
        let userMsg = ChatMessage(text: textInput, isUser: true)
        messages.append(userMsg)
        let input = textInput
        textInput = ""
        isLoading = true
        Task {
            do {
                let response = try await api.sendChat(message: input)
                await MainActor.run {
                    isLoading = false
                    if let text = response.response { messages.append(ChatMessage(text: text, isUser: false)) }
                    else if let error = response.error { messages.append(ChatMessage(text: "Error: \(error)", isUser: false, isError: true)) }
                }
            } catch {
                await MainActor.run { isLoading = false; messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false, isError: true)) }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String, isUser: Bool, isError: Bool, timestamp: Date
    init(text: String, isUser: Bool, isError: Bool = false) { self.text = text; self.isUser = isUser; self.isError = isError; self.timestamp = Date() }
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
                Text(message.text).padding(12).background(backgroundColor).foregroundColor(foregroundColor).cornerRadius(16).frame(maxWidth: 500, alignment: message.isUser ? .trailing : .leading)
                Text(message.timestamp, style: .time).font(.caption2).foregroundColor(.secondary)
            }
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var offset: CGFloat = 0
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle().fill(Color.secondary).frame(width: 6, height: 6).offset(y: offset)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: offset)
            }
        }.padding(12).background(Color(.controlBackgroundColor)).cornerRadius(16).onAppear { offset = -4 }
    }
}
