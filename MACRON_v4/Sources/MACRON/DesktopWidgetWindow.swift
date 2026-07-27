import SwiftUI
import AppKit

class DesktopWidgetWindow: NSPanel {
    static let shared = DesktopWidgetWindow()
    
    private init() {
        let view = NSHostingView(rootView: DesktopWidgetView())
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 280, height: 160),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.contentView = view
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
    }
    
    func show() { self.orderFrontRegardless() }
    func hide() { self.orderOut(nil) }
}

struct DesktopWidgetView: View {
    @State private var backendOnline = false
    @State private var lastCommand = "Esperando..."
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "brain.head.profile").foregroundColor(.accentColor)
                Text("MACRON").font(.caption.bold())
                Spacer()
                Circle().fill(backendOnline ? Color.green : Color.red).frame(width: 8, height: 8)
            }
            Divider()
            Text(lastCommand).font(.caption).lineLimit(2).foregroundColor(.secondary)
            HStack(spacing: 8) {
                Button("Abrir") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first?.makeKeyAndOrderFront(nil)
                }.buttonStyle(.borderedProminent).controlSize(.small)
                Button("Voz") {
                    NotificationCenter.default.post(name: .showVoiceAction, object: nil)
                }.buttonStyle(.bordered).controlSize(.small)
            }
        }
        .padding(12)
        .frame(width: 280, height: 160)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .onReceive(timer) { _ in checkBackend() }
        .onAppear { checkBackend() }
    }
    
    private func checkBackend() {
        URLSession.shared.dataTask(with: URL(string: "http://localhost:5001/api/health")!) { _, response, _ in
            DispatchQueue.main.async {
                backendOnline = (response as? HTTPURLResponse)?.statusCode == 200
            }
        }.resume()
    }
}
