import SwiftUI
struct FeatureGridView: View {
    let features: [FeatureItem] = [
        FeatureItem(name: "Voice Actions", icon: "mic.fill", color: .blue, code: "A"),
        FeatureItem(name: "Hotkey Pro", icon: "command", color: .indigo, code: "B"),
        FeatureItem(name: "TextToSpeech", icon: "speaker.wave.2.fill", color: .cyan, code: "C"),
        FeatureItem(name: "Dictation", icon: "waveform", color: .teal, code: "D"),
        FeatureItem(name: "Persistent Chat", icon: "bubble.left.fill", color: .green, code: "E"),
        FeatureItem(name: "Local LLM", icon: "cpu", color: .orange, code: "F"),
        FeatureItem(name: "AI Vision", icon: "eye.fill", color: .purple, code: "G"),
        FeatureItem(name: "AI Personas", icon: "person.2.fill", color: .pink, code: "H"),
        FeatureItem(name: "Smart Notes", icon: "note.text", color: .yellow, code: "I"),
        FeatureItem(name: "Productivity", icon: "chart.bar.fill", color: .red, code: "J"),
        FeatureItem(name: "Clipboard AI", icon: "doc.on.clipboard", color: .blue, code: "FN"),
        FeatureItem(name: "Quick Translate", icon: "globe", color: .green, code: "FO"),
        FeatureItem(name: "Screen Capture AI", icon: "camera.fill", color: .purple, code: "FK"),
        FeatureItem(name: "Email Draft", icon: "envelope.fill", color: .orange, code: "FL"),
        FeatureItem(name: "Window Manager", icon: "rectangle.split.2x1", color: .indigo, code: "FM"),
        FeatureItem(name: "Smart Scheduler", icon: "calendar", color: .red, code: "FI"),
        FeatureItem(name: "Document AI", icon: "doc.text", color: .teal, code: "FJ"),
        FeatureItem(name: "Code Assistant", icon: "curlybraces", color: .cyan, code: "FH"),
        FeatureItem(name: "Screen Reader", icon: "speaker.wave.3.fill", color: .pink, code: "FG"),
        FeatureItem(name: "Smart Home", icon: "house.fill", color: .green, code: "FF"),
    ]
    @State private var searchText = ""
    var filteredFeatures: [FeatureItem] {
        if searchText.isEmpty { return features }
        return features.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.code.lowercased().contains(searchText.lowercased()) }
    }
    var body: some View {
        VStack(spacing: 0) {
            TextField("Buscar feature...", text: $searchText).textFieldStyle(.roundedBorder).padding()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                    ForEach(filteredFeatures) { feature in FeatureCard(feature: feature) }
                }.padding()
            }
        }.background(Color(.windowBackgroundColor))
    }
}
struct FeatureItem: Identifiable {
    let id = UUID(); let name: String; let icon: String; let color: Color; let code: String
}
struct FeatureCard: View {
    let feature: FeatureItem
    @State private var isHovered = false
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(feature.color.opacity(0.15)).frame(width: 50, height: 50)
                Image(systemName: feature.icon).font(.title2).foregroundColor(feature.color)
            }
            Text(feature.name).font(.system(size: 12, weight: .semibold)).multilineTextAlignment(.center).lineLimit(2)
            Text(feature.code).font(.caption2).foregroundColor(.secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1)).cornerRadius(4)
        }
        .frame(height: 120).frame(maxWidth: .infinity).padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isHovered ? feature.color : Color.clear, lineWidth: 2))
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}
