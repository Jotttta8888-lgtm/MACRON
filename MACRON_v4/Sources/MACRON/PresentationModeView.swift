import SwiftUI
struct PresentationModeView: View {
    @State private var isExpanded = false
    @State private var position = CGPoint(x: 150, y: 150)
    @State private var dragOffset = CGSize.zero
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "brain.head.profile").foregroundColor(.accentColor)
                Text("MACRON").font(.caption.bold())
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up").font(.caption)
                }.buttonStyle(.plain)
            }.padding(.horizontal, 12).padding(.vertical, 8).background(Color(.controlBackgroundColor).opacity(0.8))
            if isExpanded {
                VStack(spacing: 8) {
                    TextField("Pregunta...", text: .constant("")).textFieldStyle(.roundedBorder).font(.caption)
                    HStack(spacing: 8) {
                        Button(action: {}) { Image(systemName: "mic.fill") }.buttonStyle(.borderedProminent).controlSize(.small)
                        Button(action: {}) { Image(systemName: "command") }.buttonStyle(.bordered).controlSize(.small)
                    }
                }.padding(12).frame(width: 280)
            }
        }.background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8).overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1)).position(x: position.x + dragOffset.width, y: position.y + dragOffset.height).gesture(DragGesture().onChanged { dragOffset = $0.translation }.onEnded { position.x += $0.translation.width; position.y += $0.translation.height; dragOffset = .zero }).frame(width: isExpanded ? 300 : 140, height: isExpanded ? 200 : 40).animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}
