import SwiftUI

struct Glassmorphism: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.15
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Color.accentColor.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func glassmorphism(cornerRadius: CGFloat = 16, opacity: Double = 0.15) -> some View {
        modifier(Glassmorphism(cornerRadius: cornerRadius, opacity: opacity))
    }
}

struct AnimatedEntrance: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func animatedEntrance(delay: Double = 0) -> some View {
        modifier(AnimatedEntrance(delay: delay))
    }
}
