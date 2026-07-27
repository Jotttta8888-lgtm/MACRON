import SwiftUI

struct FinderView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var query = ""
    @State private var path = "~"
    @State private var results: [FinderItem] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Buscar archivos...", text: $query).textFieldStyle(.plain).onSubmit { search() }
                TextField("Ruta", text: $path).textFieldStyle(.roundedBorder).frame(width: 150)
                Button(action: search) { Image(systemName: "arrow.right.circle.fill").font(.title3) }
                    .buttonStyle(.plain).disabled(query.isEmpty || isSearching)
            }.padding().background(Color(.controlBackgroundColor))
            
            if isSearching { ProgressView("Buscando...").padding() }
            else if results.isEmpty && !query.isEmpty { EmptyStateView(icon: "magnifyingglass", title: "Sin resultados", subtitle: "Intenta con otra busqueda") }
            else { List(results) { item in FinderItemRow(item: item) }.listStyle(.plain) }
        }.background(Color(.windowBackgroundColor))
    }
    
    private func search() {
        guard !query.isEmpty else { return }
        isSearching = true
        Task {
            do { results = (try await api.searchFiles(query: query, path: path)).results ?? [] } catch { print("Error: \(error)") }
            isSearching = false
        }
    }
}

struct FinderItemRow: View {
    let item: FinderItem
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon).font(.title3).foregroundColor(.accentColor).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.body)
                Text(item.path).font(.caption).foregroundColor(.secondary).lineLimit(1)
                HStack(spacing: 8) {
                    Text(item.type.uppercased()).font(.caption2).foregroundColor(.secondary)
                    Text(item.formattedSize).font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: { NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "") }) {
                Image(systemName: "arrow.up.right").foregroundColor(.accentColor)
            }.buttonStyle(.plain)
        }.padding(.vertical, 6)
    }
}

struct SafariView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var selectedTab = 0
    @State private var bookmarks: [Bookmark] = []
    @State private var history: [HistoryItem] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Marcadores").tag(0)
                Text("Historial").tag(1)
            }.pickerStyle(.segmented).padding()
            
            if isLoading { ProgressView().padding() }
            else if selectedTab == 0 { List(bookmarks) { BookmarkRow(bookmark: $0) }.listStyle(.plain) }
            else { List(history) { HistoryRow(item: $0) }.listStyle(.plain) }
        }
        .background(Color(.windowBackgroundColor))
        .task { await loadData() }
        .onChange(of: selectedTab) { _ in Task { await loadData() } }
    }
    
    private func loadData() async {
        isLoading = true
        if selectedTab == 0 { do { bookmarks = (try await api.getBookmarks()).bookmarks ?? [] } catch { print("Error: \(error)") } }
        else { do { history = (try await api.getHistory(limit: 50)).history ?? [] } catch { print("Error: \(error)") } }
        isLoading = false
    }
}

struct BookmarkRow: View {
    let bookmark: Bookmark
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bookmark.fill").foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title).font(.body)
                Text(bookmark.url).font(.caption).foregroundColor(.secondary).lineLimit(1)
                if let folder = bookmark.folder { Text(folder).font(.caption2).foregroundColor(.accentColor) }
            }
            Spacer()
            Button(action: { if let url = URL(string: bookmark.url) { NSWorkspace.shared.open(url) } }) {
                Image(systemName: "arrow.up.right.square").foregroundColor(.accentColor)
            }.buttonStyle(.plain)
        }.padding(.vertical, 6)
    }
}

struct HistoryRow: View {
    let item: HistoryItem
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock").foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title ?? "Sin titulo").font(.body)
                Text(item.url).font(.caption).foregroundColor(.secondary).lineLimit(1)
                if let visits = item.visitCount { Text("\(visits) visitas").font(.caption2).foregroundColor(.secondary) }
            }
            Spacer()
            Button(action: { if let url = URL(string: item.url) { NSWorkspace.shared.open(url) } }) {
                Image(systemName: "arrow.up.right.square").foregroundColor(.accentColor)
            }.buttonStyle(.plain)
        }.padding(.vertical, 6)
    }
}

struct MailView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var mailData: MailResponse?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Mail").font(.title2.bold())
                Spacer()
                if let unread = mailData?.unread, let total = mailData?.total {
                    Label("\(unread)/\(total)", systemImage: "envelope.badge").font(.caption).foregroundColor(unread > 0 ? .orange : .secondary)
                }
            }.padding()
            
            if isLoading { ProgressView().padding() }
            else if let recent = mailData?.recent, !recent.isEmpty { List(recent) { MailMessageRow(message: $0) }.listStyle(.plain) }
            else { EmptyStateView(icon: "envelope", title: "Sin correos recientes", subtitle: "No hay correos nuevos") }
        }
        .background(Color(.windowBackgroundColor))
        .task { await loadMail() }
    }
    
    private func loadMail() async {
        isLoading = true
        do { mailData = try await api.getMailSummary() } catch { print("Error: \(error)") }
        isLoading = false
    }
}

struct MailMessageRow: View {
    let message: MailMessage
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.fill").foregroundColor(.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(message.subject).font(.body).fontWeight(.medium)
                Text(message.sender).font(.caption).foregroundColor(.secondary)
                if let preview = message.preview { Text(preview).font(.caption).foregroundColor(.secondary).lineLimit(2) }
                Text(message.date).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
        }.padding(.vertical, 8)
    }
}

struct FocusView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var focusStatus: FocusResponse?
    @State private var selectedMode = "work"
    
    let modes = [
        ("work", "Trabajo", "briefcase.fill", Color.blue),
        ("personal", "Personal", "person.fill", Color.green),
        ("dnd", "No Molestar", "moon.fill", Color.indigo),
        ("sleep", "Dormir", "bed.double.fill", Color.purple)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Focus Mode").font(.title2.bold())
            if let status = focusStatus, let active = status.active {
                HStack {
                    Image(systemName: active ? "checkmark.shield.fill" : "shield").font(.title).foregroundColor(active ? .green : .secondary)
                    Text(active ? "Focus activo: \(status.mode ?? "")" : "Focus inactivo").font(.headline)
                }.padding().background(Color(.controlBackgroundColor)).cornerRadius(12)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(modes, id: \.0) { mode in
                    FocusModeCard(name: mode.1, icon: mode.2, color: mode.3, isSelected: selectedMode == mode.0) {
                        selectedMode = mode.0; toggleFocus(mode: mode.0)
                    }
                }
            }.padding(.horizontal)
            Spacer()
        }
        .padding(.top).background(Color(.windowBackgroundColor))
        .task { await loadFocusStatus() }
    }
    
    private func loadFocusStatus() async { do { focusStatus = try await api.getFocusStatus() } catch { print("Error: \(error)") } }
    private func toggleFocus(mode: String) { Task { do { focusStatus = try await api.toggleFocus(mode: mode) } catch { print("Error: \(error)") } } }
}

struct FocusModeCard: View {
    let name: String, icon: String, color: Color, isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 32))
                Text(name).font(.headline)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24)
            .background(isSelected ? color.opacity(0.2) : Color(.controlBackgroundColor))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? color : Color.clear, lineWidth: 2))
        }.buttonStyle(.plain)
    }
}
