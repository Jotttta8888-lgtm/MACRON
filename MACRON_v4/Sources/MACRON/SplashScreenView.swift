import SwiftUI

struct SplashScreenOverlay: View {
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Color(.windowBackgroundColor).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .scaleEffect(scale)
                Text("MACRON")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("100% Local AI Agent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
            }
        }
    }
}
