import SwiftUI
import AppKit

class SmartNotesService: ObservableObject {
    static let shared = SmartNotesService()
    @Published var notes: [SmartNote] = []
    private let notesDir = NSHomeDirectory() + "/Documents/MACRON/notes"
    
    struct SmartNote: Identifiable, Codable {
        var id = UUID()
        let title: String
        let content: String
        let tags: [String]
        let createdAt: Date
    }
    
    func createNote(title: String, content: String) {
        let tags = extractTags(content)
        let note = SmartNote(title: title, content: content, tags: tags, createdAt: Date())
        notes.insert(note, at: 0)
        saveNote(note)
        NotificationService.shared.send(title: "MACRON", body: "Nota guardada: " + title)
    }
    
    private func extractTags(_ text: String) -> [String] {
        let pattern = "#\\w+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        return matches.compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }
    
    private func saveNote(_ note: SmartNote) {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: notesDir, withIntermediateDirectories: true)
        let path = notesDir + "/" + note.id.uuidString + ".md"
        let md = "# " + note.title + "\n\n" + note.content + "\n\n---\nTags: " + note.tags.joined(separator: ", ") + "\nFecha: " + ISO8601DateFormatter().string(from: note.createdAt)
        try? md.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func loadNotes() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: notesDir) else { return }
        var loaded: [SmartNote] = []
        for file in files.filter({ $0.hasSuffix(".md") }) {
            let path = notesDir + "/" + file
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            let title = content.components(separatedBy: .newlines).first?.replacingOccurrences(of: "# ", with: "") ?? "Sin titulo"
            loaded.append(SmartNote(title: title, content: content, tags: [], createdAt: Date()))
        }
        notes = loaded
    }
    
    func searchNotes(_ query: String) -> [SmartNote] {
        let lower = query.lowercased()
        return notes.filter { $0.title.lowercased().contains(lower) || $0.content.lowercased().contains(lower) }
    }
}

struct QuickNoteWindow: View {
    @State private var title = ""
    @State private var content = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Nota Rapida").font(.headline)
            TextField("Titulo", text: $title)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $content)
                .frame(height: 200)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Button("Guardar") {
                    SmartNotesService.shared.createNote(title: title.isEmpty ? "Sin titulo" : title, content: content)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 320)
    }
}
