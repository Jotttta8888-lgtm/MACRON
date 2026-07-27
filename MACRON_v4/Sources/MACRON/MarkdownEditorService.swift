import Foundation
import AppKit

class MarkdownEditorService: ObservableObject {
    static let shared = MarkdownEditorService()
    @Published var documents: [MDDocument] = []
    private let docsPath = NSHomeDirectory() + "/Documents/MACRON/markdown"
    
    struct MDDocument: Identifiable, Codable {
        var id = UUID()
        var title: String
        var content: String
        let createdAt: Date
        var modifiedAt: Date
    }
    
    func createDocument(title: String, content: String = "") {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: docsPath, withIntermediateDirectories: true)
        let doc = MDDocument(title: title, content: content, createdAt: Date(), modifiedAt: Date())
        let path = docsPath + "/" + title + ".md"
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
        documents.append(doc)
    }
    
    func updateDocument(id: UUID, content: String) {
        guard let idx = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[idx].content = content
        documents[idx].modifiedAt = Date()
        let path = docsPath + "/" + documents[idx].title + ".md"
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func renderHTML(from markdown: String) -> String {
        var html = markdown
            .replacingOccurrences(of: "# ", with: "<h1>", options: .regularExpression)
            .replacingOccurrences(of: "## ", with: "<h2>", options: .regularExpression)
            .replacingOccurrences(of: "### ", with: "<h3>", options: .regularExpression)
            .replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<b>$1</b>", options: .regularExpression)
            .replacingOccurrences(of: "\\*(.+?)\\*", with: "<i>$1</i>", options: .regularExpression)
            .replacingOccurrences(of: "`(.+?)`", with: "<code>$1</code>", options: .regularExpression)
            .replacingOccurrences(of: "- (.+)", with: "<li>$1</li>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\n", with: "<br>")
        return "<html><body>" + html + "</body></html>"
    }
    
    func exportToPDF(title: String) {
        let path = docsPath + "/" + title + ".md"
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        let html = renderHTML(from: content)
        let htmlPath = docsPath + "/" + title + ".html"
        try? html.write(toFile: htmlPath, atomically: true, encoding: .utf8)
        if let url = URL(string: "file://" + htmlPath) {
            NSWorkspace.shared.open(url)
        }
    }
}
