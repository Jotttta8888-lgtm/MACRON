import SwiftUI

struct KeyboardShortcutsHelpView: View {
    @Binding var isPresented: Bool
    
    let shortcuts: [(key: String, action: String)] = [
        ("Cmd + Shift + M", "Abrir Voice Action"),
        ("Cmd + ,", "Preferencias"),
        ("Cmd + R", "Reiniciar backend"),
        ("Cmd + 1-9", "Cambiar tab"),
        ("Esc", "Cerrar panel"),
        ("Ctrl + Espacio", "Dictado universal"),
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Atajos de Teclado").font(.title2.bold())
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill").font(.title2)
                }.buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(shortcuts, id: \.key) { shortcut in
                    HStack {
                        Text(shortcut.key)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                        Spacer()
                        Text(shortcut.action)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}
