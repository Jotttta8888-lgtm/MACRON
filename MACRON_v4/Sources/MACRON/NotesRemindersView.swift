import AppKit
import AppKit
import SwiftUI
struct NotesView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var notes: [Note] = []
    @State private var showAddNote = false
    @State private var selectedNote: Note?
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNote) {
                ForEach(notes) { note in NoteRow(note: note).tag(note) }
            }
            .listStyle(.sidebar).frame(minWidth: 250)
            .toolbar { ToolbarItem { Button(action: { showAddNote = true }) { Image(systemName: "plus") } } }
        } detail: {
            if let note = selectedNote { NoteDetailView(note: note) }
            else { EmptyStateView(icon: "note.text", title: "Selecciona una nota", subtitle: "Elige una nota del panel izquierdo") }
        }
        .sheet(isPresented: $showAddNote) { AddNoteSheet(onSave: createNote, onCancel: { showAddNote = false }) }
        .task { await loadNotes() }
    }
    private func loadNotes() async { do { notes = (try await api.getNotes()).notes ?? [] } catch { print("Error: \(error)") } }
    private func createNote(title: String, content: String, tags: [String]) {
        Task { _ = try? await api.createNote(title: title, content: content, tags: tags); await loadNotes(); showAddNote = false }
    }
}
struct NoteRow: View {
    let note: Note
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Sin titulo").font(.headline)
            Text(note.content ?? "").font(.caption).foregroundColor(.secondary).lineLimit(2)
            if let tags = note.tags, !tags.isEmpty { Text(tags).font(.caption2).foregroundColor(.accentColor) }
        }.padding(.vertical, 4)
    }
}
struct NoteDetailView: View {
    let note: Note
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.title ?? "Sin titulo").font(.title.bold())
                if let tags = note.tags, !tags.isEmpty {
                    Text(tags).font(.caption).foregroundColor(.accentColor).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1)).cornerRadius(4)
                }
                Text(note.content ?? "").font(.body).frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }.padding()
        }.background(Color(.windowBackgroundColor))
    }
}
struct AddNoteSheet: View {
    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    let onSave: (String, String, [String]) -> Void
    let onCancel: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Nueva Nota").font(.title2.bold())
            DictationTextField(placeholder: "Titulo", text: $title)
            TextEditor(text: $content).frame(minHeight: 150).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            DictationTextField(placeholder: "Tags", text: $tags)
            HStack {
                Button("Cancelar", action: onCancel).buttonStyle(.bordered)
                Spacer()
                Button("Guardar") { onSave(title, content, tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }) }
                    .buttonStyle(.borderedProminent).disabled(title.isEmpty)
            }
        }.padding().frame(width: 500, height: 400)
    }
}
struct RemindersView: View {
    @EnvironmentObject var api: MacronAPIClient
    @State private var reminders: [Reminder] = []
    @State private var isLoading = false
    @State private var showAddReminder = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recordatorios").font(.title2.bold())
                Spacer()
                Button(action: { showAddReminder = true }) { Label("Nuevo", systemImage: "plus") }.buttonStyle(.borderedProminent)
            }.padding()
            if isLoading { ProgressView().padding() }
            else if reminders.isEmpty { EmptyStateView(icon: "bell.slash", title: "Sin recordatorios", subtitle: "Crea tu primer recordatorio") }
            else { List { ForEach(reminders) { reminder in ReminderRow(reminder: reminder) } }.listStyle(.plain) }
        }
        .sheet(isPresented: $showAddReminder) { AddReminderSheet(onSave: createReminder, onCancel: { showAddReminder = false }) }
        .task { await loadReminders() }
    }
    private func loadReminders() async {
        isLoading = true
        do { reminders = (try await api.getReminders()).reminders ?? [] } catch { print("Error: \(error)") }
        isLoading = false
    }
    private func createReminder(title: String, dueDate: Date?, priority: String) {
        Task {
            var dateStr: String?
            if let dueDate = dueDate { dateStr = ISO8601DateFormatter().string(from: dueDate) }
            _ = try? await api.createReminder(title: title, dueDate: dateStr, priority: priority)
            await loadReminders(); showAddReminder = false
        }
    }
}
struct ReminderRow: View {
    let reminder: Reminder
    var priorityColor: Color {
        switch reminder.priority?.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .blue
        default: return .gray
        }
    }
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: (reminder.completed ?? false) ? "checkmark.circle.fill" : "circle").foregroundColor((reminder.completed ?? false) ? .green : .secondary).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title ?? "Sin titulo").font(.body).strikethrough(reminder.completed ?? false)
                HStack(spacing: 8) {
                    if let due = reminder.dueDate { Label(due, systemImage: "calendar").font(.caption2).foregroundColor(.secondary) }
                    Circle().fill(priorityColor).frame(width: 6, height: 6)
                    Text(reminder.priority?.capitalized ?? "Normal").font(.caption2).foregroundColor(priorityColor)
                }
            }
            Spacer()
        }.padding(.vertical, 6)
    }
}
struct AddReminderSheet: View {
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority = "normal"
    let onSave: (String, Date?, String) -> Void
    let onCancel: () -> Void
    let priorities = ["low", "normal", "high"]
    var body: some View {
        VStack(spacing: 16) {
            Text("Nuevo Recordatorio").font(.title2.bold())
            DictationTextField(placeholder: "Titulo", text: $title)
            Toggle("Fecha limite", isOn: $hasDueDate)
            if hasDueDate { DatePicker("Fecha", selection: $dueDate) }
            Picker("Prioridad", selection: $priority) {
                ForEach(priorities, id: \.self) { p in Text(p.capitalized).tag(p) }
            }.pickerStyle(.segmented)
            HStack {
                Button("Cancelar", action: onCancel).buttonStyle(.bordered)
                Spacer()
                Button("Guardar") { onSave(title, hasDueDate ? dueDate : nil, priority) }
                    .buttonStyle(.borderedProminent).disabled(title.isEmpty)
            }
        }.padding().frame(width: 400)
    }
}
