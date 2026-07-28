import Foundation
import PDFKit

public final class DocumentAI: @unchecked Sendable {
    public static let shared = DocumentAI()
    private var currentDocument: PDFDocument?
    private var currentText: String = ""
    private init() {}
    
    public func loadPDF(from url: URL) -> String {
        guard let doc = PDFDocument(url: url) else { return "❌ No se pudo cargar el PDF." }
        currentDocument = doc
        currentText = extractText(from: doc)
        return "✅ PDF cargado: \(doc.pageCount) paginas, \(currentText.count) caracteres."
    }
    
    public func summarize() -> String {
        guard !currentText.isEmpty else { return "❌ No hay documento cargado. Arrastra un PDF primero." }
        let sentences = currentText.components(separatedBy: ". ")
        let keySentences = sentences.prefix(5)
        return "📄 **Resumen:**\n\n" + keySentences.joined(separator: ". ") + ".\n\n(Total: \(sentences.count) oraciones)"
    }
    
    public func answerQuestion(_ question: String) -> String {
        guard !currentText.isEmpty else { return "❌ No hay documento cargado." }
        let lowerQ = question.lowercased()
        let words = lowerQ.components(separatedBy: .whitespacesAndNewlines).filter { $0.count > 3 }
        let paragraphs = currentText.components(separatedBy: "\n\n")
        var scored: [(String, Int)] = []
        for para in paragraphs {
            let lowerP = para.lowercased()
            var score = 0
            for word in words { if lowerP.contains(word) { score += 1 } }
            if score > 0 { scored.append((para, score)) }
        }
        scored.sort { $0.1 > $1.1 }
        let top = scored.prefix(3).map { $0.0 }
        if top.isEmpty { return "🔍 No encontre informacion relevante en el documento. Prueba con otra pregunta." }
        return "📄 **Respuesta basada en el documento:**\n\n" + top.joined(separator: "\n\n---\n\n")
    }
    
    public func extractTables() -> String {
        guard !currentText.isEmpty else { return "❌ No hay documento cargado." }
        let lines = currentText.components(separatedBy: .newlines)
        var tables: [String] = []
        var currentTable: [String] = []
        for line in lines {
            let hasNumbers = line.rangeOfCharacter(from: .decimalDigits) != nil
            let hasTabs = line.contains("\t") || line.contains("  ")
            if hasNumbers && (hasTabs || line.contains("|")) { currentTable.append(line) }
            else if !currentTable.isEmpty { tables.append(currentTable.joined(separator: "\n")); currentTable = [] }
        }
        if !currentTable.isEmpty { tables.append(currentTable.joined(separator: "\n")) }
        guard !tables.isEmpty else { return "📊 No detecte tablas claras en el documento." }
        return "📊 **Tablas detectadas:**\n\n" + tables.prefix(3).enumerated().map { "Tabla \($0+1):\n\($1)" }.joined(separator: "\n\n---\n\n")
    }
    
    private func extractText(from doc: PDFDocument) -> String {
        var text = ""
        for i in 0..<doc.pageCount { if let page = doc.page(at: i) { text += page.string ?? ""; text += "\n\n" } }
        return text
    }
    
    public func searchKeyword(_ keyword: String) -> String {
        guard !currentText.isEmpty else { return "❌ No hay documento cargado." }
        let lowerK = keyword.lowercased()
        let sentences = currentText.components(separatedBy: ". ")
        var results: [String] = []
        for sentence in sentences { if sentence.lowercased().contains(lowerK) { results.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines)) } }
        if results.isEmpty { return "🔍 '\(keyword)' no aparece en el documento." }
        return "🔍 **'\(keyword)' aparece \(results.count) veces:**\n\n" + results.prefix(5).joined(separator: ".\n\n")
    }
}
