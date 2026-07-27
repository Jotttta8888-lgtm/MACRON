import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let pages: [(icon: String, title: String, description: String)] = [
        ("brain.head.profile", "Bienvenido a MACRON", "Tu agente de IA 100% local para macOS. Sin nube, sin internet necesaria."),
        ("mic.fill", "Comandos de Voz", "Di Hey MACRON o presiona Cmd+Shift+M desde cualquier app."),
        ("command", "Atajos de Teclado", "Usa Cmd+Shift+M para abrir, Esc para cerrar, Cmd+, para preferencias."),
        ("lock.shield.fill", "100% Privado", "Todo procesamiento local. Tus datos nunca salen de tu Mac."),
        ("sparkles", "Listo para usar", "MACRON se inicia automaticamente. Disfruta tu asistente personal.")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top)
            
            VStack(spacing: 16) {
                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding()
                Text(pages[currentPage].title)
                    .font(.title.bold())
                Text(pages[currentPage].description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxHeight: .infinity)
            
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button("Anterior") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Siguiente") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Comenzar") {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .frame(width: 500, height: 450)
    }
}
