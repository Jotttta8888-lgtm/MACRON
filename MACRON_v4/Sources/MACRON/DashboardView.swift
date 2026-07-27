import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var isLoading = false
    @StateObject private var perfMonitor = PerformanceMonitor()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard").font(.largeTitle.bold())
                        Text(api.status?.status ?? "Cargando...").font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: refresh) {
                        Image(systemName: "arrow.clockwise").font(.title2)
                    }.buttonStyle(.plain)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                }.padding(.horizontal)
                
                // Hardware Stats
                if let hardware = api.status?.hardware {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                        StatCard(title: "Apple Silicon", value: (hardware.appleSilicon ?? false) ? "M-Series" : "Intel", icon: "cpu", color: (hardware.appleSilicon ?? false) ? .cyan : .gray)
                        StatCard(title: "MLX", value: (hardware.mlx ?? false) ? "Activo" : "Inactivo", icon: "bolt.fill", color: (hardware.mlx ?? false) ? .green : .gray)
                        StatCard(title: "RAM", value: "\(Int(hardware.ramGb ?? 0)) GB", icon: "memorychip", color: .orange)
                        StatCard(title: "Modelo LLM", value: hardware.model ?? "Desconocido", icon: "brain", color: .purple)
                    }.padding(.horizontal)
                }
                
                // Performance Monitor
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance").font(.title2.bold())
                    HStack(spacing: 12) {
                        PerformanceCard(title: "CPU", value: "\(Int(perfMonitor.cpuUsage))%", color: .red, icon: "cpu")
                        PerformanceCard(title: "RAM", value: "\(Int(perfMonitor.ramUsage))%", color: .blue, icon: "memorychip")
                        PerformanceCard(title: "Uptime", value: perfMonitor.uptime, color: .green, icon: "clock")
                    }
                    .onAppear { perfMonitor.start() }
                    .onDisappear { perfMonitor.stop() }
                }.padding(.horizontal)
                
                // Active Modules
                if let active = api.status?.active {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Modulos Activos (\(api.status?.modulesActive ?? 0))").font(.title2.bold())
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                            ForEach(active, id: \.self) { module in ModuleBadge(name: module.capitalized, active: true) }
                        }
                    }.padding().background(Color(.controlBackgroundColor)).cornerRadius(12).padding(.horizontal)
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Acciones Rapidas").font(.title2.bold())
                    HStack(spacing: 12) {
                        QuickActionButton(title: "Screenshot", icon: "camera", color: .blue) {}
                        QuickActionButton(title: "Activar Voz", icon: "mic", color: .green) { 
                            let alert = NSAlert(); alert.messageText = "Dictado de macOS"; 
                            alert.informativeText = "Presiona Control dos veces en cualquier campo de texto para dictar."; 
                            alert.runModal() 
                        }
                        QuickActionButton(title: "Focus Mode", icon: "moon.fill", color: .indigo) {}
                    }
                }.padding(.horizontal)
                
                Spacer(minLength: 40)
            }.padding(.vertical)
        }.background(Color(.windowBackgroundColor))
    }
    
    private func refresh() {
        Task {
            defer { isLoading = false }
            isLoading = true
            _ = await api.checkHealth()
        }
    }
}

struct StatCard: View {
    let title: String, value: String, icon: String, color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: icon).font(.title2).foregroundColor(color); Spacer() }
            Text(value).font(.title3.bold()).lineLimit(1)
            Text(title).font(.caption).foregroundColor(.secondary)
        }.padding().frame(height: 100).background(Color(.controlBackgroundColor)).cornerRadius(12)
    }
}

struct ModuleBadge: View {
    let name: String, active: Bool
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(active ? Color.green : Color.gray).frame(width: 6, height: 6)
            Text(name).font(.caption)
            Spacer()
        }.padding(.horizontal, 10).padding(.vertical, 6)
        .background(active ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)).cornerRadius(8)
    }
}

struct QuickActionButton: View {
    let title: String, icon: String, color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption)
            }.frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(12)
        }.buttonStyle(.plain)
    }
}

struct PerformanceCard: View {
    let title: String, value: String, color: Color, icon: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
