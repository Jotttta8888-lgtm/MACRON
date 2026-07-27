import AppKit
import SwiftUI
struct CalendarView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var events: [CalendarEvent] = []
    @State private var isLoading = false
    @State private var showAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventDate = Date()
    @State private var newEventNotes = ""
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Calendario").font(.title2.bold())
                Spacer()
                Button(action: { showAddEvent = true }) { Label("Nuevo Evento", systemImage: "plus") }.buttonStyle(.borderedProminent)
            }.padding()
            if isLoading { ProgressView("Cargando...").padding() }
            else if events.isEmpty { EmptyStateView(icon: "calendar.badge.exclamationmark", title: "Sin eventos", subtitle: "No hay eventos para hoy") }
            else { List { ForEach(events) { event in EventRow(event: event) } }.listStyle(.plain) }
        }
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showAddEvent) {
            AddEventSheet(title: $newEventTitle, date: $newEventDate, notes: $newEventNotes, onSave: createEvent, onCancel: { showAddEvent = false })
        }
        .task { await loadEvents() }
    }
    private func loadEvents() async {
        isLoading = true
        do { events = (try await api.getTodayEvents()).events ?? [] } catch { print("Error: \(error)") }
        isLoading = false
    }
    private func createEvent() {
        Task {
            let formatter = ISO8601DateFormatter()
            _ = try? await api.createEvent(title: newEventTitle, startDate: formatter.string(from: newEventDate), notes: newEventNotes)
            await loadEvents(); showAddEvent = false; newEventTitle = ""; newEventNotes = ""
        }
    }
}
struct EventRow: View {
    let event: CalendarEvent
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar").font(.title2).foregroundColor(.accentColor).frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Sin titulo").font(.headline)
                Text(event.displayDate).font(.caption).foregroundColor(.secondary)
                if let loc = event.location, !loc.isEmpty { Label(loc, systemImage: "mappin").font(.caption2).foregroundColor(.secondary) }
                if let notes = event.notes, !notes.isEmpty { Text(notes).font(.caption).foregroundColor(.secondary).lineLimit(2) }
            }
            Spacer()
        }.padding(.vertical, 8)
    }
}
struct AddEventSheet: View {
    @Binding var title: String
    @Binding var date: Date
    @Binding var notes: String
    let onSave: () -> Void
    let onCancel: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("Nuevo Evento").font(.title2.bold())
            DictationTextField(placeholder: "Titulo", text: $title)
            DatePicker("Fecha y hora", selection: $date)
            DictationTextField(placeholder: "Notas", text: $notes)
            HStack {
                Button("Cancelar", action: onCancel).buttonStyle(.bordered)
                Spacer()
                Button("Guardar", action: onSave).buttonStyle(.borderedProminent).disabled(title.isEmpty)
            }
        }.padding().frame(width: 400)
    }
}
struct EmptyStateView: View {
    let icon: String, title: String, subtitle: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 48)).foregroundColor(.secondary)
            Text(title).font(.title3.bold())
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
