import SwiftUI
struct SidebarView: View {
    @Binding var selectedTab: Int
    @ObservedObject var brainState: BrainState
    let items = [("Dashboard", "house.fill"), ("Chat", "bubble.left.fill"), ("Features", "square.grid.2x2.fill"), ("Tools", "wrench.fill"), ("Settings", "gear")]
    var body: some View {
        List(0..<items.count, id: \.self) { index in
            Button { selectedTab = index } label: {
                HStack {
                    Image(systemName: items[index].1).frame(width: 24)
                    Text(items[index].0).font(.system(size: 14, weight: .medium))
                    Spacer()
                    if index == 0 && brainState.isRunning {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                    }
                }.padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .foregroundColor(selectedTab == index ? .accentColor : .primary)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                Button(brainState.isRunning ? "Detener Brain" : "Activar Brain") {
                    brainState.isRunning ? brainState.shutdown() : brainState.boot()
                }
                .buttonStyle(.borderedProminent)
                .tint(brainState.isRunning ? .red : .green)
                .controlSize(.small)
                Text("v4.9.5 · 171 features").font(.caption2).foregroundColor(.secondary)
            }.padding()
        }
    }
}
