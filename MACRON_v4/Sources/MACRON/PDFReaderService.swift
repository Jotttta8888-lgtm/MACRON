import Foundation
import PDFKit

class PDFReaderService {
    static let shared = PDFReaderService()
    
    func extractText(from path: String) -> String {
        guard let pdf = PDFDocument(url: URL(fileURLWithPath: path)) else { return "Error abriendo PDF" }
        let text = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined(separator: "\n")
        return text.isEmpty ? "PDF sin texto extraible" : String(text.prefix(10000))
    }
    
    func searchInPDFs(query: String, in directory: String) -> [(file: String, snippet: String)] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: directory) else { return [] }
        var results: [(String, String)] = []
        for file in files.filter({ ($0 as NSString).pathExtension.lowercased() == "pdf" }) {
            let path = directory + "/" + file
            let text = extractText(from: path).lowercased()
            if text.contains(query.lowercased()) {
                let snippet = extractSnippet(text, query: query)
                results.append((path, snippet))
            }
        }
        return results
    }
    
    private func extractSnippet(_ text: String, query: String) -> String {
        guard let range = text.range(of: query.lowercased()) else { return String(text.prefix(200)) }
        let start = text.index(range.lowerBound, offsetBy: -100, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 100, limitedBy: text.endIndex) ?? text.endIndex
        return "..." + String(text[start..<end]) + "..."
    }
}
