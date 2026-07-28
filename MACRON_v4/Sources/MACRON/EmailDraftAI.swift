import Foundation
import AppKit

public final class EmailDraftAI: @unchecked Sendable {
    public static let shared = EmailDraftAI()
    private let templates: [String: (subject: String, body: String)] = [
        "formal": ("Asunto importante", "Estimado/a [nombre],\n\nEspero que se encuentre bien. Me dirijo a usted para [motivo].\n\n[contenido]\n\nQuedo a la espera de su respuesta.\n\nSaludos cordiales,\n[remitente]"),
        "informal": ("Hola!", "Hola [nombre],\n\n[contenido]\n\nNos vemos,\n[remitente]"),
        "seguimiento": ("Seguimiento: [tema]", "Hola [nombre],\n\nTe escribo para dar seguimiento a [tema].\n\n[contenido]\n\nQuedo atento,\n[remitente]"),
        "agradecimiento": ("Gracias!", "Hola [nombre],\n\nQueria agradecerte por [razon].\n\n[contenido]\n\nUn abrazo,\n[remitente]")
    ]
    private init() {}
    
    public func draftEmail(to: String, about: String, tone: String = "formal") -> String {
        guard let template = templates[tone.lowercased()] else { return "❌ Tono '\(tone)' no disponible. Opciones: formal, informal, seguimiento, agradecimiento." }
        let body = template.body.replacingOccurrences(of: "[nombre]", with: to).replacingOccurrences(of: "[contenido]", with: about).replacingOccurrences(of: "[remitente]", with: NSFullUserName())
        let subject = template.subject.replacingOccurrences(of: "[tema]", with: String(about.prefix(30)))
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = String(body.prefix(500)).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailto = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"
        if let url = URL(string: mailto) { NSWorkspace.shared.open(url) }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(body, forType: .string)
        return "✅ Borrador de email generado y abierto en Mail.app.\n📋 Tambien copiado al portapapeles.\n\n**Asunto:** \(subject)\n**Para:** \(to)\n\n**Cuerpo:**\n\(body)"
    }
    
    public func parseAndDraft(_ command: String) -> String {
        let lower = command.lowercased()
        var to = "destinatario@ejemplo.com"
        if let range = lower.range(of: " a ") {
            let after = String(lower[range.upperBound...])
            let words = after.components(separatedBy: .whitespacesAndNewlines)
            if let first = words.first, !first.isEmpty { to = first.capitalized }
        }
        var about = ""
        let triggers = ["diciendo que ", "diciendo ", "sobre ", "que ", "para "]
        for trigger in triggers { if let range = lower.range(of: trigger) { about = String(lower[range.upperBound...]).capitalized; break } }
        if about.isEmpty { about = "Mensaje importante" }
        var tone = "formal"
        if lower.contains("gracias") || lower.contains("agradecer") { tone = "agradecimiento" }
        else if lower.contains("seguimiento") || lower.contains("follow") { tone = "seguimiento" }
        else if lower.contains("hola") || lower.contains("informal") { tone = "informal" }
        return draftEmail(to: to, about: about, tone: tone)
    }
}
