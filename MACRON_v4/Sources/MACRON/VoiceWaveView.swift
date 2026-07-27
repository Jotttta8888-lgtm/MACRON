import SwiftUI

struct VoiceWaveView: View {
    @Binding var isActive: Bool
    
    @State private var phase: Double = 0
    @State private var barHeights: [CGFloat] = Array(repeating: 5, count: 7)
    private let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Ondas circulares de fondo
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        Color.orange.opacity(0.3 - Double(i) * 0.08),
                        lineWidth: 2
                    )
                    .frame(width: 60 + CGFloat(i) * 40, height: 60 + CGFloat(i) * 40)
                    .scaleEffect(isActive ? 1.2 + CGFloat(i) * 0.15 : 0.8)
                    .opacity(isActive ? 1.0 : 0.2)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.3),
                        value: isActive
                    )
            }
            
            // Barritas centrales
            HStack(spacing: 6) {
                ForEach(0..<barHeights.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 6, height: barHeights[index])
                        .animation(.easeInOut(duration: 0.15), value: barHeights[index])
                }
            }
            
            // Circulo central pulsante
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.orange.opacity(0.8), .red.opacity(0.4)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
                .frame(width: 20, height: 20)
                .scaleEffect(isActive ? 1.3 : 0.9)
                .opacity(isActive ? 1.0 : 0.5)
                .animation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true),
                    value: isActive
                )
        }
        .onReceive(timer) { _ in
            if isActive {
                withAnimation(.easeInOut(duration: 0.1)) {
                    barHeights = barHeights.map { _ in
                        CGFloat.random(in: 8...50)
                    }
                }
            } else {
                barHeights = Array(repeating: 5, count: 7)
            }
        }
    }
}

struct VoiceWaveView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceWaveView(isActive: .constant(true))
            .frame(width: 200, height: 200)
            .background(Color.black)
    }
}
