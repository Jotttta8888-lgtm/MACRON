import Foundation
import PDFKit

class PersonalKnowledgeBase: ObservableObject {
    static let shared = PersonalKnowledgeBase()
    @Published var indexedFiles: [String] = []
    @Published var lastQueryResults: [String] = []
    private let indexPath = NSHomeDirectory() + "/Documents/MACRON/kb_index.json"
    private var index: [String: String] = [:]
    
    func buildIndex() {
        let docs = NSHomeDirectory() + "/Documents"
        let fm = FileManager.default
        var newIndex: [String: String] = [:]
        
        func scan(_ path: String) {
            guard let items = try? fm.contentsOfDirectory(atPath: path) else { return }
            for item in items {
                if item.hasPrefix(".") || item == "MACRON" { continue }
                let full = path + "/" + item
                var isDir: ObjCBool = false
                fm.fileExists(atPath: full, isDirectory: &isDir)
                if isDir.boolValue {
                    scan(full)
                } else {
                    let ext = (item as NSString).pathExtension.lowercased()
                    if ext == "txt" || ext == "md" || ext == "swift" || ext == "py" {
                        if let content = try? String(contentsOfFile: full, encoding: .utf8) {
                            newIndex[full] = String(content.prefix(5000))
                        }
                    } else if ext == "pdf" {
                        if let pdf = PDFDocument(url: URL(fileURLWithPath: full)) {
                            let text = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined(separator: "\n")
                            newIndex[full] = String(text.prefix(5000))
                        }
                    }
                }
            }
        }
        
        scan(docs)
        index = newIndex
        indexedFiles = Array(index.keys)
        saveIndex()
        NotificationService.shared.send(title: "MACRON", body: "KB indexado: " + String(index.count) + " archivos")
    }
    
    func search(_ query: String) -> [(file: String, snippet: String)] {
        let lower = query.lowercased()
        var results: [(file: String, snippet: String)] = []
        for (path, content) in index {
            if content.lowercased().contains(lower) {
                let snippet = extractSnippet(content, query: lower)
                results.append((path, snippet))
            }
        }
        lastQueryResults = results.map { $0.file }
        return results.sorted { $0.file < $1.file }
    }
    
    private func extractSnippet(_ text: String, query: String) -> String {
        guard let range = text.lowercased().range(of: query) else { return String(text.prefix(200)) }
        let start = text.index(range.lowerBound, offsetBy: -100, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 100, limitedBy: text.endIndex) ?? text.endIndex
        return "..." + String(text[start..<end]) + "..."
    }
    
    private func saveIndex() {
        let data = try? JSONSerialization.data(withJSONObject: index, options: .prettyPrinted)
        try? data?.write(to: URL(fileURLWithPath: indexPath))
    }
    
    func loadIndex() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: indexPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }
        index = json
        indexedFiles = Array(index.keys)
    }
}
