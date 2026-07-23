import AppKit
import SwiftUI
struct ResearchView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var query = ""
    @State private var results: [ResearchResult] = []
    @State private var summary = ""
    @State private var isSearching = false
    @State private var maxResults = 5
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Research Agent").font(.title2.bold())
                Spacer()
                Picker("Resultados", selection: $maxResults) {
                    Text("5").tag(5); Text("10").tag(10); Text("20").tag(20)
                }.pickerStyle(.segmented).frame(width: 120)
            }.padding()
            HStack(spacing: 12) {
                Image(systemName: "globe").foregroundColor(.accentColor)
                NativeTextField(text: $query, placeholder: "Buscar en la web...", onSubmit: { search() })
                Button(action: search) {
                    Image(systemName: isSearching ? "arrow.clockwise" : "magnifyingglass").font(.title3)
                }.buttonStyle(.plain).disabled(query.isEmpty || isSearching)
            }.padding().background(Color(.controlBackgroundColor))
            if isSearching { ProgressView("Buscando...").padding() }
            else if !summary.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !summary.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Resumen").font(.headline)
                                Text(summary).font(.body)
                            }.padding().background(Color(.controlBackgroundColor)).cornerRadius(12)
                        }
                        Text("Fuentes").font(.headline).padding(.horizontal)
                        ForEach(results) { ResearchResultRow(result: $0) }
                    }.padding()
                }
            } else if !query.isEmpty { EmptyStateView(icon: "magnifyingglass", title: "Sin resultados", subtitle: "Intenta con otra busqueda") }
        }.background(Color(.windowBackgroundColor))
    }
    private func search() {
        guard !query.isEmpty else { return }
        isSearching = true; results = []; summary = ""
        Task {
            do {
                let response = try await api.research(query: query, maxResults: maxResults)
                results = response.results ?? []; summary = response.summary ?? ""
            } catch { print("Error: \(error)") }
            isSearching = false
        }
    }
}
struct ResearchResultRow: View {
    let result: ResearchResult
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.title ?? "Sin titulo").font(.headline).foregroundColor(.accentColor)
            if let snippet = result.snippet { Text(snippet).font(.body).foregroundColor(.secondary).lineLimit(3) }
            Text(result.url ?? "").font(.caption).foregroundColor(.accentColor).lineLimit(1)
        }
        .padding().background(Color(.controlBackgroundColor)).cornerRadius(12)
        .onTapGesture { if let url = URL(string: result.url ?? "") { NSWorkspace.shared.open(url) } }
    }
}
struct AnalyticsView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var analytics: AnalyticsResponse?
    @State private var isLoading = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Analytics").font(.title2.bold())
                Spacer()
                Button(action: { Task { await loadAnalytics() } }) { Image(systemName: "arrow.clockwise") }.buttonStyle(.plain)
            }.padding()
            if isLoading { ProgressView().padding() }
            else if let stats = analytics?.stats {
                ScrollView {
                    VStack(spacing: 20) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                            StatCard(title: "Interacciones", value: "\(stats.totalInteractions ?? 0)", icon: "bubble.left.fill", color: .blue)
                            StatCard(title: "Tokens", value: "\(stats.totalTokens ?? 0)", icon: "textformat", color: .green)
                            StatCard(title: "Tiempo Promedio", value: String(format: "%.2fs", stats.avgResponseTime ?? 0), icon: "clock", color: .orange)
                        }.padding(.horizontal)
                        if let topModules = stats.topModules, !topModules.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Modulos mas usados").font(.headline)
                                ForEach(topModules, id: \.self) { module in
                                    HStack { Text(module.capitalized).font(.body); Spacer(); Image(systemName: "chart.bar.fill").foregroundColor(.accentColor) }
                                    .padding().background(Color(.controlBackgroundColor)).cornerRadius(8)
                                }
                            }.padding(.horizontal)
                        }
                        if let daily = stats.dailyUsage, !daily.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Uso Diario").font(.headline)
                                VStack(spacing: 8) {
                                    ForEach(daily) { day in
                                        HStack {
                                            Text(day.date ?? "").font(.caption).frame(width: 80, alignment: .leading)
                                            GeometryReader { geo in
                                                RoundedRectangle(cornerRadius: 4).fill(Color.accentColor)
                                                    .frame(width: CGFloat(day.count ?? 0) / CGFloat(maxCount(daily)) * (geo.size.width - 40), height: 20)
                                            }
                                            Text("\(day.count ?? 0)").font(.caption).frame(width: 30, alignment: .trailing)
                                        }
                                    }
                                }
                            }.padding().background(Color(.controlBackgroundColor)).cornerRadius(12).padding(.horizontal)
                        }
                        Spacer(minLength: 40)
                    }.padding(.vertical)
                }
            } else { EmptyStateView(icon: "chart.bar", title: "Sin datos", subtitle: "No hay estadisticas disponibles") }
        }.background(Color(.windowBackgroundColor)).task { await loadAnalytics() }
    }
    private func loadAnalytics() async {
        isLoading = true
        do { analytics = try await api.getAnalytics() } catch { print("Error: \(error)") }
        isLoading = false
    }
    private func maxCount(_ usage: [DailyUsage]) -> Int { usage.map { $0.count ?? 0 }.max() ?? 1 }
}
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var autoStart = false
    @State private var showNotifications = true
    @State private var darkMode = true
    @State private var selectedPort = "5001"
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preferencias").font(.title2.bold())
                Spacer()
                Button("Cerrar") { dismiss() }.keyboardShortcut(.escape, modifiers: [])
            }.padding()
            Form {
                Section("General") {
                    Toggle("Iniciar automaticamente", isOn: $autoStart)
                    Toggle("Notificaciones", isOn: $showNotifications)
                    Toggle("Modo oscuro", isOn: $darkMode)
                }
                Section("Conexion") {
                    HStack { Text("Puerto API"); Spacer(); NativeTextField(text: $selectedPort, placeholder: "Puerto", onSubmit: nil).frame(width: 80) }
                    HStack { Text("Backend Python"); Spacer(); Text("~/Documents/MACRON").foregroundColor(.secondary) }
                }
                Section("Acerca de") {
                    HStack { Text("Version"); Spacer(); Text("MACRON v4.0").foregroundColor(.secondary) }
                    HStack { Text("SwiftUI"); Spacer(); Text("Fase 4").foregroundColor(.secondary) }
                }
            }.formStyle(.grouped)
            Spacer()
        }.frame(width: 450, height: 400)
    }
}
struct MenuBarView: View {
    @EnvironmentObject var api: MacronAPIClient
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "cpu").font(.title2).foregroundColor(.accentColor)
                Text("MACRON").font(.headline)
                Spacer()
                Circle().fill(api.isOnline ? Color.green : Color.red).frame(width: 8, height: 8)
            }.padding()
            Divider()
            VStack(spacing: 8) {
                if let active = api.status?.active {
                    ForEach(active.prefix(5), id: \.self) { module in
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption)
                            Text(module.capitalized).font(.caption)
                            Spacer()
                        }
                    }
                }
            }.padding()
            Divider()
            VStack(spacing: 4) {
                Button("Abrir Dashboard") { NSApp.activate(ignoringOtherApps: true) }.buttonStyle(.plain)
                Button("Chat Rapido") { NSApp.activate(ignoringOtherApps: true); NotificationCenter.default.post(name: .showChat, object: nil) }.buttonStyle(.plain)
                Button("Calendario") { NSApp.activate(ignoringOtherApps: true); NotificationCenter.default.post(name: .showCalendar, object: nil) }.buttonStyle(.plain)
            }.padding()
            Divider()
            Button("Salir") { NSApp.terminate(nil) }.buttonStyle(.plain).foregroundColor(.red).padding()
        }.frame(width: 220)
    }
}
