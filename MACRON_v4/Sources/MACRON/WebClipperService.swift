import Foundation

class WebClipperService: ObservableObject {
    static let shared = WebClipperService()
    @Published var clips: [WebClip] = []
    private let dbPath = NSHomeDirectory() + "/Documents/MACRON/webclips.json"
    
    struct WebClip: Identifiable, Codable {
        var id = UUID()
        let url: String
        let title: String
        let content: String
        var highlights: [String]
        let savedAt: Date
    }
    
    func clipPage(url: String, title: String, html: String) {
        let markdown = htmlToMarkdown(html)
        let clip = WebClip(url: url, title: title, content: markdown, highlights: [], savedAt: Date())
        clips.insert(clip, at: 0)
        save()
        NotificationService.shared.send(title: "MACRON Web Clipper", body: "Guardado: " + title)
    }
    
    func addHighlight(clipId: UUID, text: String) {
        guard let idx = clips.firstIndex(where: { $0.id == clipId }) else { return }
        clips[idx].highlights.append(text)
        save()
    }
    
    func searchClips(query: String) -> [WebClip] {
        let lower = query.lowercased()
        return clips.filter {
            $0.title.lowercased().contains(lower) || $0.content.lowercased().contains(lower)
        }
    }
    
    private func htmlToMarkdown(_ html: String) -> String {
        let md = html
            .replacingOccurrences(of: "<h1[^>]*>(.+?)</h1>", with: "# $1", options: .regularExpression)
            .replacingOccurrences(of: "<h2[^>]*>(.+?)</h2>", with: "## $1", options: .regularExpression)
            .replacingOccurrences(of: "<p[^>]*>(.+?)</p>", with: "$1\\n\\n", options: .regularExpression)
            .replacingOccurrences(of: "<a[^>]+href=\"([^\"]+)\"[^>]*>(.+?)</a>", with: "[$2]($1)", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return md
    }
    
    private func save() {
        let data = try? JSONEncoder().encode(clips)
        try? data?.write(to: URL(fileURLWithPath: dbPath))
    }
    
    func load() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath)),
              let decoded = try? JSONDecoder().decode([WebClip].self, from: data) else { return }
        clips = decoded
    }
}
